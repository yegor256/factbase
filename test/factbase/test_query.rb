# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require 'time'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/query'
require_relative '../../lib/factbase/logged'
require_relative '../../lib/factbase/pre'
require_relative '../../lib/factbase/impatient'
require_relative '../../lib/factbase/inv'
require_relative '../../lib/factbase/rules'
require_relative '../../lib/factbase/tallied'
require_relative '../../lib/factbase/cached/cached_factbase'
require_relative '../../lib/factbase/indexed/indexed_factbase'
require_relative '../../lib/factbase/sync/sync_factbase'

# Query test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestQuery < Factbase::Test
  def test_stories
    with_factbases do |badge, fb|
      Dir[File.join(__dir__, '../../fixtures/stories/**/*.yml')].each do |fixture|
        base = File.basename(fixture)
        story = YAML.load_file(fixture)
        2.times do
          fb.query('(always)').delete!
          story['facts'].each do |y|
            f = fb.insert
            y.each do |k, vv|
              vv = [vv] unless vv.is_a?(Array)
              vv.each do |v|
                f.send(:"#{k}=", v)
              end
            end
          end
          story['queries'].each do |q|
            qry = q['query']
            if q['size']
              size = q['size']
              assert_equal(size, fb.query(qry).each.to_a.size, "#{base}: #{qry} at #{badge}")
              fb.txn do |fbt|
                facts = fbt.query(qry).each.to_a
                assert_equal(size, facts.size, "#{base}: #{qry} at #{badge} (in txn)")
                facts.each do |fact|
                  refute_empty(fact.all_properties)
                  refute_nil(fact.to_s)
                end
              end
            else
              ret = q['one']
              assert_equal(ret, fb.query(qry).one, "#{base}: #{qry} at #{badge}")
              fb.txn do |fbt|
                assert_equal(ret, fbt.query(qry).one, "#{base}: #{qry} at #{badge} (in txn)")
              end
            end
          end
        end
      end
    end
  end

  def test_simple_parsing
    maps = []
    maps << { 'foo' => [42] }
    q = Factbase::Query.new(maps, '(eq foo 42)', Factbase.new)
    assert_equal(
      1,
      q.each do |f|
        assert_equal(42, f.foo)
      end
    )
  end

  def test_complex_parsing
    queries = {
      '(eq num 444)' => 0,
      '(eq hi 4)' => 1,
      '(eq time 0)' => 0,
      '(gt num 60)' => 1,
      '(gt hi 3)' => 1,
      "(and (lt pi 100) \n\n (gt num 1000))" => 0,
      '(exists pi)' => 1,
      '(eq pi +3.14)' => 1,
      '(not (exists hello))' => 3,
      '(eq "Integer" (type num))' => 2,
      '(eq "Integer" (type hi))' => 1,
      '(when (eq num 0) (exists time))' => 2,
      '(unique num)' => 1,
      '(unique name)' => 2,
      '(unique pi)' => 1,
      '(many num)' => 1,
      '(one num)' => 2,
      '(nil (agg (exists hello) (min num)))' => 3,
      '(gt num (minus 1 (either (at 0 (prev num)) 0)))' => 3,
      '(and (not (many num)) (eq num (plus 21 +21)))' => 1,
      '(and (not (many num)) (eq num (minus -100 -142)))' => 1,
      '(and (one num) (eq num (times 7 6)))' => 1,
      '(and (one pi) (eq pi (div -6.28 -2)))' => 1,
      '(gt (size num) 2)' => 1,
      '(matches name "^[a-z]+$")' => 1,
      '(matches nome "^Walter$")' => 1,
      '(lt (size num) 2)' => 2,
      '(eq (size _hello) 0)' => 3,
      '(eq num pi)' => 0,
      '(absent time)' => 2,
      '(eq pi (agg (eq num 0) (sum pi)))' => 1,
      '(eq num (agg (exists oops) (count)))' => 2,
      '(lt num (agg (eq num 0) (max pi)))' => 2,
      '(eq time (min time))' => 1,
      '(and (absent time) (exists pi))' => 1,
      "(and (exists time) (not (\t\texists pi)))" => 1,
      '(undef something)' => 3,
      "(or (eq num +66) (lt time #{(Time.now - 200).utc.iso8601}))" => 1,
      '(eq 3 (agg (eq num $num) (count)))' => 1,
      '(and (eq num 42) (not (empty (eq name "Jeff"))))' => 2,
      '(and (eq num 42) (empty (eq x $name)))' => 2,
      '(and (eq num 42) (not (empty (eq name $name))))' => 2
    }
    maps = [
      { 'num' => [42], 'name' => ['Jeff'] },
      { 'num' => [42, 66, 0], 'pi' => [3.14], 'name' => ['peter'] },
      { 'num' => [0], 'time' => [Time.now - 100], 'hi' => [4], 'nome' => ['Walter'] }
    ]
    3.times do |cycle|
      with_factbases(maps) do |badge, fb|
        queries.each do |q, r|
          assert_equal(r, fb.query(q).each.to_a.size, "#{q} in #{badge} (cycle ##{cycle})")
          fb.txn do |fbt|
            assert_equal(r, fbt.query(q).each.to_a.size, "#{q} in #{badge} (txn, cycle ##{cycle})")
          end
        end
      end
    end
  end

  def test_simple_parsing_with_time
    maps = []
    now = Time.now.utc
    maps << { 'foo' => [now] }
    q = Factbase::Query.new(maps, "(eq foo #{now.iso8601})", Factbase.new)
    assert_equal(1, q.each.to_a.size)
  end

  def test_simple_deleting
    maps = [
      { 'foo' => [42] },
      { 'bar' => [4, 5] },
      { 'bar' => [5] }
    ]
    q = Factbase::Query.new(maps, '(eq bar 5)', Factbase.new)
    assert_equal(2, q.delete!)
    assert_equal(1, maps.size)
  end

  def test_reading_one
    maps = [
      { 'foo' => [42], 'hello' => [4] },
      { 'bar' => [4, 5] }
    ]
    with_factbases(maps) do |badge, fb|
      {
        '(agg (and (eq foo 42) (eq hello $v)) (min foo))' => 42,
        '(agg (or (eq foo 42) (eq bar 4)) (min foo))' => 42,
        '(agg (exists foo) (first foo))' => [42],
        '(agg (exists z) (first z))' => nil,
        '(agg (always) (count))' => 2,
        '(agg (eq bar $v) (count))' => 1,
        '(agg (eq foo 42) (min foo))' => 42,
        '(agg (and (eq foo 42)) (min foo))' => 42,
        '(agg (eq z 40) (count))' => 0
      }.each do |q, expected|
        result = fb.query(q).one(fb, 'v' => 4)
        if expected.nil?
          assert_nil(result, "#{q} -> nil in #{badge}")
        else
          assert_equal(expected, result, "#{q} -> #{expected} in #{badge}")
        end
      end
    end
  end

  def test_deleting_nothing
    maps = [
      { 'foo' => [42] },
      { 'bar' => [4, 5] },
      { 'bar' => [5] }
    ]
    with_factbases(maps) do |badge, fb|
      q = fb.query('(never)')
      assert_equal(0, q.delete!, "#{q} in #{badge}")
      assert_equal(3, maps.size, "#{q} in #{badge}")
    end
  end

  def test_finds_with_substitution
    maps = [{ 'foo' => [42] }, { 'bar' => [7] }, { 'foo' => [666] }]
    with_factbases(maps) do |badge, fb|
      assert_equal(0, fb.query('(eq 2 (agg (eq foo $foo) (count)))').each.to_a.size, "with #{badge}")
      fb.txn do |fbt|
        assert_equal(0, fbt.query('(eq 2 (agg (eq foo $foo) (count)))').each.to_a.size, "with #{badge} (txn)")
      end
    end
  end

  def test_scans_and_inserts
    with_factbases do |_, fb|
      fb.insert.foo = 42
      before = fb.size
      more = 0
      fb.query('(exists foo)').each do |f|
        fb.insert.bar = f.foo
        more += 1
      end
      assert_equal(before + more, fb.size)
    end
  end

  def test_scans_and_inserts_in_txn
    with_factbases do |_, fb|
      fb.insert.foo = 42
      before = fb.size
      more = 0
      fb.query('(exists foo)').each do |f|
        fb.txn do |fbt|
          fbt.insert.bar = f.foo
          more += 1
        end
      end
      assert_equal(before + more, fb.size)
    end
  end

  def test_scans_and_inserts_in_queried_txn
    with_factbases do |_, fb|
      fb.insert.foo = 42
      before = fb.size
      more = 0
      fb.txn do |fbt|
        fbt.query('(exists foo)').each do |f|
          fbt.insert.bar = f.foo
          more += 1
        end
      end
      assert_equal(before + more, fb.size)
    end
  end

  def test_scans_and_appends_in_queried_txn
    with_factbases do |badge, fb|
      fb.insert.foo = 42
      fb.txn do |fbt|
        fbt.query('(exists foo)').each do |f|
          f.bar = 33
        end
        refute_empty(fbt.query('(exists bar)').each.to_a, "in #{badge}")
      end
      refute_empty(fb.query('(exists bar)').each.to_a, "in #{badge}")
      assert_empty(fb.query('(and (exists foo) (not (exists bar)))').each.to_a, "in #{badge}")
    end
  end

  def test_turns_query_to_string
    with_factbases do |badge, fb|
      assert_equal('(always)', fb.query('(always)').to_s, "Fails with #{badge}")
    end
  end

  def test_to_array
    maps = []
    maps << { 'foo' => [42] }
    assert_equal(1, Factbase::Query.new(maps, '(eq foo 42)', Factbase.new).each.to_a.size)
  end

  def test_returns_int
    maps = []
    maps << { 'foo' => [1] }
    q = Factbase::Query.new(maps, '(eq foo 1)', Factbase.new)
    assert_equal(1, q.each(&:to_s))
  end

  def test_with_aliases
    maps = []
    maps << { 'foo' => [42] }
    assert_equal(45, Factbase::Query.new(maps, '(as bar (plus foo 3))', Factbase.new).each.to_a[0].bar)
    assert_equal(1, maps[0].size)
  end

  def test_with_params
    maps = [
      { 'foo' => [42] },
      { 'foo' => [17] }
    ]
    found = 0
    Factbase::Query.new(maps, '(eq foo $bar)', Factbase.new).each(Factbase.new, bar: [42]) do
      found += 1
    end
    assert_equal(1, found)
    assert_equal(1, Factbase::Query.new(maps, '(eq foo $bar)', Factbase.new).each(Factbase.new, bar: [42]).to_a.size)
    assert_equal(0, Factbase::Query.new(maps, '(eq foo $bar)', Factbase.new).each(Factbase.new, bar: [555]).to_a.size)
  end

  def test_with_nil_alias
    maps = [{ 'foo' => [42] }]
    assert_nil(Factbase::Query.new(maps, '(as bar (plus xxx 3))', Factbase.new).each.to_a[0]['bar'])
  end

  def test_get_all_properties
    maps = [{ 'foo' => [42] }]
    f = Factbase::Query.new(maps, '(always)', Factbase.new).each.to_a[0]
    assert_includes(f.all_properties, 'foo')
  end

  private

  def with_factbases(maps = [], &)
    {
      'plain' => Factbase.new(maps),
      'plain+impatient' => Factbase::Impatient.new(Factbase.new(maps)),
      'pre+plain' => Factbase::Pre.new(Factbase.new(maps)) { nil },
      'rules+plain' => Factbase::Rules.new(Factbase.new(maps), '(always)'),
      'inv+plain' => Factbase::Inv.new(Factbase.new(maps)) { nil },
      'sync+plain' => Factbase::SyncFactbase.new(Factbase.new(maps)),
      'tallied+plain' => Factbase::Tallied.new(Factbase.new(maps)),
      'indexed+plain' => Factbase::IndexedFactbase.new(Factbase.new(maps)),
      'indexed+logged+plain' => Factbase::IndexedFactbase.new(
        Factbase::Logged.new(
          Factbase.new(maps),
          Loog::NULL
        )
      ),
      'cached+plain' => Factbase::CachedFactbase.new(Factbase.new(maps)),
      'cached+logged+plain' => Factbase::CachedFactbase.new(
        Factbase::Logged.new(
          Factbase.new(maps),
          Loog::NULL
        )
      ),
      'logged+plain' => Factbase::Logged.new(Factbase.new(maps), Loog::NULL),
      'indexed+cached+plain' => Factbase::IndexedFactbase.new(
        Factbase::CachedFactbase.new(Factbase.new(maps))
      ),
      'indexed+cached+rules+plain' => Factbase::IndexedFactbase.new(
        Factbase::CachedFactbase.new(
          Factbase::Rules.new(
            Factbase.new(maps),
            '(always)',
            uid: '_id'
          )
        )
      ),
      'cached+indexed+plain' => Factbase::CachedFactbase.new(
        Factbase::IndexedFactbase.new(Factbase.new(maps))
      ),
      'indexed+indexed+plain' => Factbase::IndexedFactbase.new(
        Factbase::IndexedFactbase.new(Factbase.new(maps))
      ),
      'cached+cached+cached+plain' => Factbase::CachedFactbase.new(
        Factbase::CachedFactbase.new(
          Factbase::CachedFactbase.new(
            Factbase.new(maps)
          )
        )
      ),
      'tallied+pre+rules+inv+plain' => Factbase::Tallied.new(
        Factbase::Pre.new(
          Factbase::Rules.new(
            Factbase::Inv.new(
              Factbase.new(maps)
            ) { nil },
            '(always)'
          )
        ) { nil }
      ),
      'sync+cached+indexed+plain' => Factbase::SyncFactbase.new(
        Factbase::CachedFactbase.new(
          Factbase::IndexedFactbase.new(
            Factbase.new(maps)
          )
        )
      ),
      'sync+logged+plain' => Factbase::SyncFactbase.new(
        Factbase::Logged.new(
          Factbase.new(maps),
          Loog::NULL
        )
      ),
      'sync+cached+indexed+logged+plain' => Factbase::SyncFactbase.new(
        Factbase::CachedFactbase.new(
          Factbase::IndexedFactbase.new(
            Factbase::Logged.new(
              Factbase.new(maps),
              Loog::NULL
            )
          )
        )
      ),
      'sync+sync+sync+plain' => Factbase::SyncFactbase.new(
        Factbase::SyncFactbase.new(
          Factbase::SyncFactbase.new(
            Factbase::SyncFactbase.new(
              Factbase.new(maps)
            )
          )
        )
      ),
      'logged+logged+logged+plain' => Factbase::SyncFactbase.new(
        Factbase::Logged.new(
          Factbase::Logged.new(
            Factbase::Logged.new(
              Factbase.new(maps),
              Loog::NULL
            ),
            Loog::NULL
          ),
          Loog::NULL
        )
      ),
      'all+plain' => Factbase::Tallied.new(
        Factbase::Pre.new(
          Factbase::Rules.new(
            Factbase::Inv.new(
              Factbase::SyncFactbase.new(
                Factbase::CachedFactbase.new(
                  Factbase::IndexedFactbase.new(
                    Factbase::Logged.new(
                      Factbase.new(maps),
                      Loog::NULL
                    )
                  )
                )
              )
            ) { nil },
            '(always)'
          )
        ) { nil }
      )
    }.each(&)
  end
end
