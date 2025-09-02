# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/logged'
require_relative '../../lib/factbase/cached/cached_factbase'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestLogged < Factbase::Test
  def test_simple_setting
    fb = Factbase::Logged.new(Factbase.new, Loog::NULL)
    fb.insert
    fb.insert.bar = 3
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

  def test_reading_one
    fb = Factbase::Logged.new(Factbase.new, Loog::NULL)
    fb.insert
    fb.insert.bar = 42
    assert_equal(1, fb.query('(agg (exists bar) (count))').one)
    assert_equal([42], fb.query('(agg (exists bar) (first bar))').one)
  end

  def test_avoid_inner_logging
    buf = Loog::Buffer.new
    fb = Factbase.new
    fb.insert
    fb.insert.bar = 42
    fb = Factbase::Logged.new(Factbase::CachedFactbase.new(fb), buf)
    fb.query('(agg (exists bar) (count))').one
    fb.query('(join "foo<=bar" (exists bar))').each.to_a
    refute_includes(buf.to_s, '\'(count)\'')
    refute_includes(buf.to_s, '\'(exists bar)\'')
  end

  def test_with_txn
    log = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, log)
    assert(
      fb.txn do |fbt|
        fbt.insert.foo = 42
      end
    )
    assert_equal(1, fb.size)
    assert_includes(log.to_s, 'touched', log)
  end

  def test_with_slow_txn
    log = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, log, time_tolerate: 0.1)
    fb.txn { sleep 0.4 }
    assert_includes(log.to_s, '(slow!)', log)
  end

  def test_with_txn_rollback
    log = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, log)
    assert_equal(0, fb.txn { raise Factbase::Rollback })
    assert_equal(0, fb.size)
    assert_includes(log.to_s, 'rolled back', log)
    refute_includes(log.to_s, 'didn\'t touch', log)
  end

  def test_with_modifying_txn
    log = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, log)
    fb.insert.foo = 1
    assert_equal(0, fb.txn { |fbt| fbt.query('(always)').each.to_a }.to_i, log)
    assert_equal(1, fb.txn { |fbt| fbt.query('(always)').each.to_a[0].foo = 42 }.to_i)
    assert_includes(log.to_s, 'touched', log)
  end

  def test_with_empty_txn
    log = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, log)
    assert_equal(0, fb.txn { |fbt| fbt.query('(always)').each.to_a }.to_i)
    assert_includes(log.to_s, 'touched', log)
  end

  def test_returns_int
    fb = Factbase.new
    fb.insert
    fb.insert
    assert_equal(2, Factbase::Logged.new(fb, Loog::NULL).query('(always)').each(&:to_s))
  end

  def test_returns_int_when_empty
    fb = Factbase.new
    assert_equal(0, Factbase::Logged.new(fb, Loog::NULL).query('(always)').each(&:to_s))
  end

  def test_returns_to_s_correctly
    fb = Factbase.new
    q = '(always)'
    assert_equal(q, fb.query(q).to_s)
  end

  def test_logs_when_enumerator
    fb = Factbase::Logged.new(Factbase.new, Loog::NULL)
    assert_equal(0, fb.query('(always)').each.to_a.size)
    fb.insert
    assert_equal(1, fb.query('(always)').each.to_a.size)
  end

  def test_proper_logging
    log = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, log)
    fb.insert
    fb.insert.bar = 3
    fb.insert
    fb.insert.str =
      "Он поскорей звонит. Вбегает
      К нему слуга француз Гильо,
      Халат и туфли предлагает
      И подает ему белье.
      Спешит Онегин одеваться,
      Слуге велит приготовляться
      С ним вместе ехать и с собой
      Взять также ящик боевой.
      Готовы санки беговые.
      Он сел, на мельницу летит.
      Примчались. Он слуге велит
      Лепажа стволы роковые
      Нести за ним, а лошадям
      Отъехать в поле к двум дубкам."
    fb.query('(exists bar)').each(&:to_s)
    fb.query('(not (exists bar))').delete!
    [
      'Inserted new fact #1',
      'Inserted new fact #2',
      'Set \'bar\' to 3 (Integer)',
      'Set \'str\' to "Он поскорей звонит. Вбегает\n   ... Отъехать в поле к двум дубкам." (String)',
      'Found 1/4 fact(s) by (exists bar)',
      'Deleted 3 fact(s) out of 4 by (not (exists bar))'
    ].each do |s|
      assert_includes(log.to_s, s, "#{log}\n")
    end
  end
end
