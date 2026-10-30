# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/cached/cached_factbase'
require_relative '../../lib/factbase/logged'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestLogged < Factbase::Test
  # A log that keeps the level of every message, unlike Loog::Buffer.
  class Recorder
    attr_reader :lines

    def initialize
      @lines = []
    end

    def debug(msg)
      @lines << [:debug, msg]
    end

    def warn(msg)
      @lines << [:warn, msg]
    end
  end

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

  def test_shortens_the_value_found_by_one
    buf = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, buf)
    fb.insert.body = 'x' * 10_000
    assert_equal(10_000, fb.query('(agg (always) (first body))').one.first.length)
    found = buf.to_s.lines.find { |l| l.include?('Found') }
    assert_operator(found.length, :<, 200, found)
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
    fb.txn { sleep(0.4) }
    assert_includes(log.to_s, '(slow!)', log)
  end

  def test_logs_a_slow_operation_as_a_warning
    log = Recorder.new
    Factbase::Logged.new(Factbase.new, log, time_tolerate: 0).insert
    line = log.lines.find { |l| l[1].include?('Inserted new fact') }
    assert_equal(:warn, line[0], log.lines.inspect)
    assert_includes(line[1], '(slow!)', log.lines.inspect)
  end

  def test_logs_a_fast_operation_as_debug
    log = Recorder.new
    Factbase::Logged.new(Factbase.new, log).insert
    assert_equal(:debug, log.lines.find { |l| l[1].include?('Inserted new fact') }[0], log.lines.inspect)
  end

  def test_logs_the_id_of_a_touched_transaction
    log = Recorder.new
    fb = Factbase::Logged.new(Factbase.new, log)
    fb.txn { |fbt| fbt.insert.foo = 42 }
    assert_match(/Txn #\d+ touched/, log.lines.find { |l| l[1].start_with?('Txn #') }[1], log.lines.inspect)
  end

  def test_with_txn_rollback
    log = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, log)
    assert_predicate(fb.txn { raise(Factbase::Rollback) }, :zero?)
    assert_equal(0, fb.size)
    assert_includes(log.to_s, 'rolled back', log)
    refute_includes(log.to_s, 'didn\'t touch', log)
  end

  def test_with_txn_thrown_rollback
    log = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, log)
    fb.txn do |fbt|
      fbt.insert.foo = 1
      throw(:rollback)
    end
    assert_equal(0, fb.size)
    assert_includes(log.to_s, 'rolled back', log)
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
    assert_equal(0, Factbase::Logged.new(Factbase.new, Loog::NULL).query('(always)').each(&:to_s))
  end

  def test_returns_to_s_correctly
    q = '(always)'
    assert_equal(q, Factbase.new.query(q).to_s)
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
      'Set \'str\' to "Он поскорей звонит. Вбегает\n ...тъехать в поле к двум дубкам." (String)',
      'Found 1/4 fact(s) by (exists bar)',
      'Deleted 3 fact(s) out of 4 by (not (exists bar))'
    ].each do |s|
      assert_includes(log.to_s, s, "#{log}\n")
    end
  end

  def test_keeps_the_offset_of_a_logged_time
    t = Time.new(2026, 10, 4, 12, 0, 0, '+03:00')
    Factbase::Logged.new(Factbase.new, Loog::NULL).insert.when = t
    assert_equal(3 * 60 * 60, t.utc_offset, 'the logged time was moved to UTC')
  end

  def test_logs_the_fraction_of_a_time
    buf = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, buf)
    fb.insert.when = Time.utc(2026, 10, 19, 12, 0, 0.25r)
    fb.insert.when = Time.utc(2026, 10, 19, 12, 0, 0.75r)
    assert_includes(buf.to_s, "Set 'when' to 2026-10-19T12:00:00.250000000Z (Time)", buf.to_s)
    assert_includes(buf.to_s, "Set 'when' to 2026-10-19T12:00:00.750000000Z (Time)", buf.to_s)
  end

  def test_logs_a_time_of_whole_seconds_without_fraction
    buf = Loog::Buffer.new
    Factbase::Logged.new(Factbase.new, buf).insert.when = Time.new(2026, 10, 19, 15, 0, 0, '+03:00')
    assert_includes(buf.to_s, "Set 'when' to 2026-10-19T12:00:00Z (Time)", buf.to_s)
  end

  def test_reports_the_size_of_the_maps_it_ran_over
    buf = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, buf)
    10.times { |i| fb.insert.i = i }
    fb.query('(gt i 0)', fb.each.to_a.first(3)).each.to_a
    fb.query('(gt i 1000)', []).delete!
    assert_includes(buf.to_s, 'Found 2/3 fact(s)', buf.to_s)
    assert_includes(buf.to_s, 'There were no facts', buf.to_s)
  end
end
