# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_time'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'to_time' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToTime < Factbase::Test
  def test_to_time
    assert_equal('Time', Factbase::ToTime.new([%w[2023-01-01 hello]]).evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_keeps_fraction_of_time_value
    t = Time.utc(2024, 1, 1, 10, 0, 0, 750_000)
    assert_equal(t, Factbase::ToTime.new([t]).evaluate(fact, [], Factbase.new))
  end

  def test_rejects_unparsable_value
    t = Factbase::ToTime.new(['hello'])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact, [], Factbase.new)
      end
    assert_includes(e.message, "Cannot parse 'hello' as Time in (to_time ...):")
    assert_includes(e.message, 'no time information')
  end

  def test_rejects_out_of_range_value
    t = Factbase::ToTime.new(['2024-13-45'])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact, [], Factbase.new)
      end
    assert_includes(e.message, "Cannot parse '2024-13-45' as Time in (to_time ...):")
    assert_includes(e.message, 'argument out of range')
  end

  def test_reads_integer_as_seconds_since_epoch
    seed = Random.new_seed
    n = Random.new(seed).rand(0..2_000_000_000)
    assert_equal(
      Time.at(n).utc, Factbase::ToTime.new([:t]).evaluate(fact('t' => n), [], Factbase.new),
      "integer #{n} was not read as seconds since the epoch, seed #{seed}"
    )
  end

  def test_reads_negative_integer_as_seconds_before_epoch
    seed = Random.new_seed
    n = Random.new(seed).rand(-2_000_000_000..-1)
    assert_equal(
      Time.at(n).utc, Factbase::ToTime.new([:t]).evaluate(fact('t' => n), [], Factbase.new),
      "negative integer #{n} was not read as seconds before the epoch, seed #{seed}"
    )
  end

  def test_reads_float_as_seconds_since_epoch
    seed = Random.new_seed
    n = Random.new(seed).rand * 2_000_000_000
    assert_equal(
      Time.at(n).utc, Factbase::ToTime.new([:t]).evaluate(fact('t' => n), [], Factbase.new),
      "float #{n} was not read as seconds since the epoch, seed #{seed}"
    )
  end

  def test_reads_back_integer_made_of_time
    seed = Random.new_seed
    fb = Factbase.new
    fb.insert.t = Time.at(Random.new(seed).rand(0..2_000_000_000))
    assert_equal(
      1, fb.query('(eq (to_time (to_integer t)) t)').each.to_a.size,
      "time made into an integer was not read back, seed #{seed}"
    )
  end

  def test_reads_back_float_made_of_time
    seed = Random.new_seed
    fb = Factbase.new
    fb.insert.t = Time.at(Random.new(seed).rand(0..2_000_000_000))
    assert_equal(
      1, fb.query('(eq (to_time (to_float t)) t)').each.to_a.size,
      "time made into a float was not read back, seed #{seed}"
    )
  end

  def test_refuses_an_impossible_date
    %w[2026-02-30T00:00:00Z 2026-04-31T00:00:00Z 2025-02-29T00:00:00Z].each do |s|
      assert_raises(RuntimeError, s) { Factbase::ToTime.new([s]).evaluate(fact, [], Factbase.new) }
    end
    assert_equal(29, Factbase::ToTime.new(['2024-02-29T00:00:00Z']).evaluate(fact, [], Factbase.new).day)
  end

  def test_refuses_an_impossible_date_written_with_slashes
    assert_raises(RuntimeError, 'February 30 with slashes is not refused') do
      Factbase::ToTime.new(['2026/02/30']).evaluate(fact, [], Factbase.new)
    end
  end

  def test_refuses_an_impossible_date_without_padding
    assert_raises(RuntimeError, 'February 30 without padding is not refused') do
      Factbase::ToTime.new(['2026-2-30']).evaluate(fact, [], Factbase.new)
    end
  end

  def test_refuses_an_impossible_date_with_the_day_first
    assert_raises(RuntimeError, 'February 30 with the day first is not refused') do
      Factbase::ToTime.new(['30 Feb 2026']).evaluate(fact, [], Factbase.new)
    end
  end

  def test_refuses_an_impossible_date_with_the_month_first
    assert_raises(RuntimeError, 'February 30 with the month first is not refused') do
      Factbase::ToTime.new(['Feb 30, 2026']).evaluate(fact, [], Factbase.new)
    end
  end

  def test_refuses_an_impossible_date_written_without_separators
    assert_raises(RuntimeError, 'February 30 without separators is not refused') do
      Factbase::ToTime.new(['20260230']).evaluate(fact, [], Factbase.new)
    end
  end

  def test_reads_a_leap_day_written_with_slashes
    assert_equal(
      29, Factbase::ToTime.new(['2028/02/29']).evaluate(fact, [], Factbase.new).day,
      'a real leap day with slashes is not read as the 29th'
    )
  end

  def test_reads_midnight_written_as_the_end_of_a_day
    assert_equal(
      2, Factbase::ToTime.new(['2026-01-01 24:00:00']).evaluate(fact, [], Factbase.new).day,
      'the end of January 1 is not read as the start of January 2'
    )
  end
end
