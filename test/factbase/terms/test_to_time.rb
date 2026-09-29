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
end
