# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_time'

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

  def test_returns_nil_for_empty_operand_array
    assert_nil(Factbase::ToTime.new([[]]).evaluate(fact, [], Factbase.new))
  end

  def test_returns_nil_for_absent_property
    assert_nil(Factbase::ToTime.new([:absent_field]).evaluate(fact, [], Factbase.new))
  end

  def test_returns_nil_when_property_is_not_present_in_query
    fb = Factbase.new
    fb.insert.title = 'sample'
    assert_equal(1, fb.query('(absent (to_time timestamp))').each.to_a.size)
  end

  def test_parses_iso_string_inside_query
    fb = Factbase.new
    fb.insert.when = '2025-05-15T12:00:00Z'
    assert_equal(1, fb.query('(gt (to_time when) (to_time "2025-01-01T00:00:00Z"))').each.to_a.size)
  end

  def test_parses_integer_epoch_inside_query
    fb = Factbase.new
    fb.insert.epoch = 1_700_000_000
    assert_equal(1, fb.query('(eq (to_time epoch) (to_time 1700000000))').each.to_a.size)
  end

  def test_handles_empty_array_expression_gracefully
    assert_nil(Factbase::ToTime.new([[]]).evaluate(fact, [], Factbase.new))
  end

  def test_returns_time_instance_for_already_time_value
    now = Time.now.utc
    assert_equal(now, Factbase::ToTime.new([[now]]).evaluate(fact, [], Factbase.new))
  end

  def test_parses_formatted_date_time_string
    parsed = Factbase::ToTime.new([['2026-11-04 03:00:00 UTC']]).evaluate(fact, [], Factbase.new)
    assert_equal(2026, parsed.year)
    assert_equal(11, parsed.month)
    assert_equal(4, parsed.day)
  end

  def test_compares_multiple_fact_times_in_query
    fb = Factbase.new
    fb.insert.t1 = '2026-01-01T00:00:00Z'
    fb.insert.t1 = '2026-06-01T00:00:00Z'
    assert_equal(2, fb.query('(gt (to_time t1) (to_time "2025-01-01T00:00:00Z"))').each.to_a.size)
  end
end
