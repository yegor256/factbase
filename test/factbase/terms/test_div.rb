# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/div'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'div' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestDiv < Factbase::Test
  def test_div_numbers
    assert_equal(420, Factbase::Div.new([:balance, 100]).evaluate(fact('balance' => 42_000), [], Factbase.new))
  end

  def test_div_integers_without_flooring
    assert_in_delta(3.5, Factbase::Div.new([:total, 2]).evaluate(fact('total' => 7), [], Factbase.new))
    assert_in_delta(-3.5, Factbase::Div.new([:total, 2]).evaluate(fact('total' => -7), [], Factbase.new))
  end

  def test_div_by_integer_zero
    t = Factbase::Div.new([:balance, 0])
    assert_includes(
      assert_raises(ArgumentError) do
        t.evaluate(fact('balance' => 42), [], Factbase.new)
      end.message,
      'Cannot divide by zero'
    )
  end

  def test_div_by_float_zero
    t = Factbase::Div.new([:balance, 0.0])
    assert_includes(
      assert_raises(ArgumentError) do
        t.evaluate(fact('balance' => 42.0), [], Factbase.new)
      end.message,
      'Cannot divide by zero'
    )
  end

  def test_div_times_not_supported
    t = Factbase::Div.new([:warranty, Time.new(2024, 1, 1)])
    assert_includes(
      assert_raises(NoMethodError) do
        t.evaluate(fact('warranty' => Time.new(2026, 1, 1)), [], Factbase.new)
      end.message,
      'undefined method'
    )
  end

  def test_divides_big_integer_exactly
    seed = Random.new_seed
    rnd = Random.new(seed)
    big = rnd.rand((2**60)..(2**70))
    k = rnd.rand(2..1000)
    assert_equal(
      big, Factbase::Div.new([:total, k]).evaluate(fact('total' => big * k), [], Factbase.new),
      "quotient of #{big * k} by #{k} lost precision, seed #{seed}"
    )
  end

  def test_keeps_integer_for_whole_quotient
    seed = Random.new_seed
    rnd = Random.new(seed)
    n = rnd.rand(-1000..1000)
    k = rnd.rand(1..1000)
    assert_instance_of(
      Integer, Factbase::Div.new([:total, k]).evaluate(fact('total' => n * k), [], Factbase.new),
      "quotient of #{n * k} by #{k} is not an integer, seed #{seed}"
    )
  end

  def test_keeps_float_for_float_operand
    seed = Random.new_seed
    k = Random.new(seed).rand(1..1000)
    assert_instance_of(
      Float, Factbase::Div.new([:total, k]).evaluate(fact('total' => k * 2.0), [], Factbase.new),
      "quotient of float #{k * 2.0} by #{k} is not a float, seed #{seed}"
    )
  end

  def test_finds_big_integer_divided_by_one
    seed = Random.new_seed
    big = Random.new(seed).rand((2**60)..(2**70))
    fb = Factbase.new
    fb.insert.id = big
    assert_equal(
      1, fb.query("(eq (div id 1) #{big})").each.to_a.size,
      "big integer #{big} divided by one is not itself, seed #{seed}"
    )
  end
end
