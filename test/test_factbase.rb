# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'loog'
require 'threads'
require_relative '../lib/factbase'
require_relative '../lib/factbase/rules'
require_relative '../lib/factbase/inv'
require_relative '../lib/factbase/pre'
require_relative '../lib/factbase/looged'

# Factbase main module test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestFactbase < Minitest::Test
  def test_injects_data_correctly
    maps = []
    fb = Factbase.new(maps)
    fb.insert
    f = fb.insert
    f.foo = 1
    f.bar = 2
    f.bar = 3
    assert_equal(2, maps.size)
    assert_equal(0, maps[0].size)
    assert_equal(2, maps[1].size)
    assert_equal([1], maps[1]['foo'])
    assert_equal([2, 3], maps[1]['bar'])
  end

  def test_query_many_times
    fb = Factbase.new
    total = 5
    total.times { fb.insert }
    total.times do
      assert_equal(5, fb.query('(always)').each.to_a.size)
    end
  end

  def test_simple_setting
    fb = Factbase.new
    fb.insert
    fb.insert.bar = 88
    found = 0
    fb.query('(exists bar)').each do |f|
      assert_predicate(f.bar, :positive?)
      f.foo = 42
      assert_equal(42, f.foo)
      found += 1
    end
    assert_equal(1, found)
    assert_equal(2, fb.size)
  end

  def test_modify_via_query
    fb = Factbase.new
    fb.insert.bar = 1
    fb.query('(exists bar)').each do |f|
      f.bar = 42
      assert_equal(2, f['bar'].size)
    end
    found = 0
    fb.query('(always)').each do |f|
      assert_equal(2, f['bar'].size)
      found += 1
    end
    assert_equal(1, found)
    assert_equal(2, fb.query('(always)').each.to_a[0]['bar'].size)
  end

  def test_serialize_and_deserialize
    f1 = Factbase.new
    f2 = Factbase.new
    f1.insert.foo = 42
    Tempfile.open do |f|
      File.binwrite(f.path, f1.export)
      f2.import(File.binread(f.path))
    end
    assert_equal(1, f2.query('(eq foo 42)').each.to_a.size)
  end

  def test_reads_from_empty_file
    fb = Factbase.new
    Tempfile.open do |f|
      File.binwrite(f.path, '')
      assert_includes(
        assert_raises(StandardError) do
          fb.import(File.binread(f.path))
        end.message, 'cannot load a factbase'
      )
    end
  end

  def test_empty_or_not
    fb = Factbase.new
    assert_equal(0, fb.size)
    fb.insert
    assert_equal(1, fb.size)
  end

  def test_txn_returns_boolean
    fb = Factbase.new
    assert_equal(1, fb.txn(&:insert).to_i)
    assert_equal(1, fb.txn { |fbt| fbt.insert.bar = 42 }.to_i)
    assert_equal(0, fb.txn { |fbt| fbt.query('(always)').each.to_a }.to_i)
    assert_equal(2, fb.txn { |fbt| fbt.query('(always)').each { |f| f.hello = 33 } }.to_i)
    assert_equal(1, fb.txn { |fbt| fbt.query('(always)').each.to_a[0].zzz = 33 }.to_i)
  end

  def test_appends_in_txn
    fb = Factbase.new
    fb.insert.foo = 443
    assert(fb.txn { |fbt| fbt.query('(always)').each { |f| f.hello = 33 } })
  end

  def test_run_txn
    fb = Factbase.new
    fb.txn do |fbt|
      fbt.insert.bar = 42
      fbt.insert.z = 42
    end
    assert_equal(2, fb.size)
    assert_includes(
      assert_raises(StandardError) do
        fb.txn do |fbt|
          fbt.insert.foo = 42
          throw 'intentionally'
        end
      end.message, 'intentionally'
    )
    assert_equal(2, fb.size)
  end

  def test_deals_with_arrays_in_txn
    fb = Factbase.new
    n = fb.insert
    n.foo = 1
    n.foo = 2
    fb.txn do |fbt|
      f = fbt.query('(gt foo 0)').each.to_a.first
      assert_equal(1, f.foo)
    end
  end

  def test_run_txn_via_query
    fb = Factbase.new
    fb.insert.foo = 1
    assert(
      fb.txn do |fbt|
        fbt.query('(always)').each { |f| f.foo = 42 }
      end
    )
    assert_equal([1, 42], fb.query('(always)').each.to_a[0]['foo'])
  end

  def test_run_txn_with_inv
    fb = Factbase::Inv.new(Factbase.new) { |_p, v| throw 'oops' if v == 42 }
    fb.insert.bar = 3
    fb.insert.foo = 5
    assert_equal(2, fb.size)
    assert_includes(
      assert_raises(StandardError) do
        fb.txn do |fbt|
          fbt.insert.foo = 42
        end
      end.message, 'oops'
    )
    assert_equal(2, fb.size)
  end

  def test_all_decorators
    [
      Factbase::Rules.new(Factbase.new, '(always)'),
      Factbase::Inv.new(Factbase.new) { |_, _| true },
      Factbase::Pre.new(Factbase.new) { |_| true },
      Factbase::Looged.new(Factbase.new, Loog::NULL)
    ].each do |d|
      f = d.insert
      f.foo = 42
      d.txn do |fbt|
        fbt.insert.bar = 455
      end
      assert_raises(StandardError) do
        d.txn do |fbt|
          fbt.insert
          throw 'oops'
        end
      end
      d.import(d.export)
      assert_equal(4, d.size)
      assert_equal(4, d.query('(always)').each.to_a.size)
    end
  end

  def test_txn_inside_query
    fb = Factbase.new
    fact = fb.insert
    fact.foo = 42
    fact.foo = 555
    fb.query('(exists foo)').each do |f|
      fb.txn do |fbt|
        assert_equal(42, fb.query('(always)').each.to_a.first.foo)
        assert_equal(42, fb.query('(always)').each.to_a.first['foo'].first)
        fbt.insert.bar = 33
      end
      f.xyz = 1
    end
    assert_equal(1, fb.query('(exists xyz)').each.to_a.size)
  end

  def test_txn_with_rollback
    fb = Factbase.new
    n = fb.insert
    n.bar = 55
    modified =
      fb.txn do |fbt|
        fbt.insert.bar = 33
        fbt.query('(eq bar 55)').each.to_a.first.boom = 44
        raise Factbase::Rollback
      end
    assert_equal(0, modified.to_i)
    assert_equal(1, fb.query('(always)').each.to_a.size)
    assert_equal(0, fb.query('(exists boom)').each.to_a.size)
  end

  def test_modifies_existing_fact_in_txn
    fb = Factbase.new
    n = fb.insert
    n.foo = 1
    fb.txn do |fbt|
      f = fbt.query('(always)').each.to_a.first
      f.bar = 2
    end
    assert_equal(1, fb.query('(eq foo 1)').each.to_a.size)
  end

  def test_simple_concurrent_inserts
    fb = Factbase.new
    t = Concurrent.processor_count * 20
    Threads.new(t).assert do
      fb.insert
    end
    assert_equal(t, fb.size)
  end

  def test_simple_concurrent_inserts_in_txns
    fb = Factbase.new
    t = Concurrent.processor_count * 7
    mul = 23
    Threads.new(t).assert do
      assert(
        fb.txn do |fbt|
          mul.times do |m|
            fbt.insert.foo = m
          end
        end
      )
    end
    assert_equal(t * mul, fb.size)
  end

  def test_simple_concurrent_inserts_in_txns_with_sleep
    fb = Factbase.new
    t = Concurrent.processor_count * 13
    mul = 53
    Threads.new(t).assert do
      assert(
        fb.txn do |fbt|
          sleep(0.01)
          mul.times do |m|
            fbt.insert.foo = m
          end
        end
      )
    end
    assert_equal(t * mul, fb.size)
  end

  def test_concurrent_inserts
    fb = Factbase.new
    t = Concurrent.processor_count * 20
    Threads.new(t).assert do
      fact = fb.insert
      fact.foo = 42
      fact.bar = 49
      fact.value = fact.foo * fact.bar
    end
    assert_equal(t, fb.size)
    assert_equal(t, fb.query('(eq foo 42)').each.to_a.size)
    assert_equal(t, fb.query('(eq bar 49)').each.to_a.size)
    assert_equal(t, fb.query("(eq value #{42 * 49})").each.to_a.size)
  end

  def test_different_values_when_concurrent_inserts
    fb = Factbase.new
    t = Concurrent.processor_count * 16
    Threads.new(t).assert do |i|
      fb.insert.foo = i
    end
    assert_equal(t, fb.size)
    Threads.new(t) do |i|
      f = fb.query("(eq foo #{i})").each.to_a
      assert_equal(1, f.count)
      assert_equal(i, f.first.foo)
    end
  end

  # @todo #98:1h I assumed that the test `test_different_properties_when_concurrent_inserts` would be passed.
  # I see like this:
  # ```
  # [2024-08-22 21:14:53.962] ERROR -- Expected: 1
  # Actual: 0: nil
  # [2024-08-22 21:14:53.962] ERROR -- Expected: 1
  # Actual: 0: nil
  # test_different_properties_when_concurrent_inserts              ERROR (0.01s)
  # Minitest::UnexpectedError:         RuntimeError: Only 0 out of 5 threads completed successfully
  #           /home/suban/.rbenv/versions/3.3.4/lib/ruby/gems/3.3.0/gems/threads-0.4.0/lib/threads.rb:73:in `assert'
  #           test/test_factbase.rb:265:in `test_different_properties_when_concurrent_inserts'
  # ```
  def test_different_properties_when_concurrent_inserts
    skip('Does not work')
    fb = Factbase.new
    Threads.new(5).assert do |i|
      fb.insert.send(:"prop_#{i}=", i)
    end
    assert_equal(5, fb.size)
    Threads.new(5).assert do |i|
      prop = "prop_#{i}"
      f = fb.query("(eq #{prop} #{i})").each.to_a
      assert_equal(1, f.count)
      assert_equal(i, f.first.send(prop.to_sym))
    end
  end

  # @todo #98:1h I assumed that the test `test_concurrent_transactions_inserts` would be passed.
  # I see like this:
  # ```
  # Expected: 100
  # Actual: 99
  # D:/a/factbase/factbase/test/test_factbase.rb:281:in `test_concurrent_transactions_inserts'
  # ```
  # See details here https://github.com/yegor256/factbase/actions/runs/10492255419/job/29068637032
  def test_concurrent_transactions_inserts
    skip('Does not work')
    t = Concurrent.processor_count * 19
    fb = Factbase.new
    Threads.new(t).assert do |i|
      fb.txn do |fbt|
        fact = fbt.insert
        fact.thread_id = i
      end
    end
    assert_equal(t, fb.size)
    assert_equal(t, fb.query('(exists thread_id)').each.to_a.size)
  end

  def test_concurrent_transactions_with_rollbacks
    fb = Factbase.new
    Threads.new.assert do |i|
      fb.txn do |fbt|
        fact = fbt.insert
        fact.thread_id = i
        raise Factbase::Rollback
      end
    end
    assert_equal(0, fb.size)
  end

  def test_concurrent_transactions_successful
    fb = Factbase.new
    t = Concurrent.processor_count * 17
    Threads.new(t).assert do |i|
      fb.txn do |fbt|
        fact = fbt.insert
        fact.thread_id = i
        fact.value = i * 10
      end
    end
    facts = fb.query('(exists thread_id)').each.to_a
    assert_equal(t, facts.size)
    facts.each do |fact|
      assert_equal(fact.value, fact.thread_id * 10)
    end
  end

  # @todo #98:1h I assumed that the test `test_concurrent_queries` would be passed.
  # I see like this:
  # ```
  # [2024-08-22 17:40:19.224] ERROR -- Expected: [0, 1]
  # Actual: [0, 0]: nil
  # [2024-08-22 17:40:19.224] ERROR -- Expected: [0, 1]
  # Actual: [0, 0]: nil
  # test_concurrent_queries                                        ERROR (0.00s)
  # Minitest::UnexpectedError:         RuntimeError: Only 0 out of 2 threads completed successfully
  #           /home/suban/.rbenv/versions/3.3.4/lib/ruby/gems/3.3.0/gems/threads-0.4.0/lib/threads.rb:73:in `assert'
  #           test/test_factbase.rb:329:in `test_concurrent_queries'
  # ```
  def test_concurrent_queries
    skip('Does not work')
    fb = Factbase.new
    Threads.new(2).assert do |i|
      fact = fb.insert
      fact.thread_id = i
      fact.value = i * 10
    end
    Threads.new(2).assert do
      results = fb.query('(exists thread_id)').each.to_a
      assert_equal(2, results.size)
      thread_ids = results.map(&:thread_id)
      assert_equal((0..1).to_a, thread_ids.sort)
    end
  end

  def test_export_import_concurrent
    fb = Factbase.new
    Threads.new(100).assert do
      fact = fb.insert
      fact.value = 42
    end
    Threads.new(5).assert do
      new_fb = Factbase.new
      new_fb.import(fb.export)
      assert_equal(fb.size, new_fb.size)
      facts = fb.query('(eq value 42)').each.to_a
      assert_equal(100, facts.size)
      facts.each do |fact|
        new_fact = new_fb.query("(eq value #{fact.value})").each.to_a.first
        assert_equal(fact.value, new_fact.value)
      end
    end
  end

  def test_dup_concurrent
    fb = Factbase.new
    mutex = Mutex.new
    Threads.new(100).assert do
      fact = fb.insert
      fact.foo = 42
    end
    fbs = []
    Threads.new(100).assert do
      mutex.synchronize do
        fbs << fb.dup
      end
    end
    assert_equal(100, fbs.size)
    fbs.each do |factbase|
      assert_equal(100, factbase.query('(eq foo 42)').each.to_a.size)
    end
  end
end
