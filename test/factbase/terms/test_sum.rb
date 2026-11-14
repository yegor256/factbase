# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/sum'

require_relative '../../test__helper'

# Test for sum term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSum < Factbase::Test
  def test_sum_regular_values
    assert_equal(
      60,
      Factbase::Sum.new([:value]).evaluate(
        fact, [{ 'value' => 10 }, { 'value' => 20 }, { 'value' => 30 }],
        Factbase.new
      )
    )
  end

  def test_sum_with_absent_values
    assert_equal(
      0,
      Factbase::Sum.new([:absent]).evaluate(fact, [{ 'value' => 40 }, {}, { 'value' => 50 }], Factbase.new)
    )
  end

  def test_sums_all_values_of_one_fact
    assert_equal(
      65,
      Factbase::Sum.new([:cost]).evaluate(
        fact, [{ 'cost' => [10, 20, 30] }, { 'cost' => 5 }], Factbase.new
      )
    )
  end

  def test_refuses_non_number_after_the_first_value
    assert_includes(
      assert_raises(ArgumentError) do
        Factbase::Sum.new([:cost]).evaluate(fact, [{ 'cost' => [10, 'oops'] }], Factbase.new)
      end.message, "The value 'oops' of the 'cost' property is not a number"
    )
  end

  def test_refuses_extra_operands
    assert_includes(
      assert_raises(ArgumentError) do
        Factbase::Sum.new(%i[a b]).evaluate(fact, [{ 'a' => 1, 'b' => 10 }], Factbase.new)
      end.message,
      "Too many (2) operands for 'sum' (1 expected)"
    )
  end

  def test_names_the_property_and_the_value
    fb = Factbase.new
    fb.insert.name = 'alice'
    assert_includes(
      assert_raises(StandardError) do
        fb.query('(gt (sum name) 0)').each.to_a
      end.message, "The value 'alice' of the 'name' property is not a number"
    )
  end
end
