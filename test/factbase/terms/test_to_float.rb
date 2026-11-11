# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_float'

require_relative '../../test__helper'

# Test for 'to_float' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToFloat < Factbase::Test
  def test_to_float
    assert_equal('Float', Factbase::ToFloat.new([[3.14, 'hello']]).evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_rejects_invalid_value
    assert_includes(
      assert_raises(RuntimeError) { Factbase::ToFloat.new(['abc']).evaluate(fact, [], Factbase.new) }.message,
      "Cannot convert 'abc' to Float in (to_float ...):"
    )
  end

  def test_converts_time_to_epoch_seconds
    assert_in_delta(
      1_704_103_200.5,
      Factbase::ToFloat.new([Time.utc(2024, 1, 1, 10, 0, 0, 500_000)]).evaluate(fact, [], Factbase.new)
    )
  end

  def test_returns_nil_for_empty_operand_array
    assert_nil(Factbase::ToFloat.new([[]]).evaluate(fact, [], Factbase.new))
  end

  def test_returns_nil_for_absent_property
    assert_nil(Factbase::ToFloat.new([:absent_num]).evaluate(fact, [], Factbase.new))
  end

  def test_returns_nil_when_property_is_absent_in_query
    fb = Factbase.new
    fb.insert.title = 'hello'
    assert_equal(1, fb.query('(absent (to_float weight))').each.to_a.size)
  end

  def test_converts_integer_to_float
    assert_in_delta(42.0, Factbase::ToFloat.new([[42]]).evaluate(fact, [], Factbase.new))
  end

  def test_converts_string_number_to_float
    assert_in_delta(12.34, Factbase::ToFloat.new([['12.34']]).evaluate(fact, [], Factbase.new))
  end

  def test_converts_negative_float_string
    assert_in_delta(-99.5, Factbase::ToFloat.new([['-99.5']]).evaluate(fact, [], Factbase.new))
  end

  def test_compares_floats_inside_query
    fb = Factbase.new
    fb.insert.price = '19.99'
    assert_equal(1, fb.query('(gt (to_float price) 15.0)').each.to_a.size)
    assert_equal(1, fb.query('(lt (to_float price) 25.0)').each.to_a.size)
  end

  def test_converts_zero_integer_to_float
    assert_in_delta(0.0, Factbase::ToFloat.new([[0]]).evaluate(fact, [], Factbase.new))
  end

  def test_converts_scientific_notation_string
    assert_in_delta(1500.0, Factbase::ToFloat.new([['1.5e3']]).evaluate(fact, [], Factbase.new))
  end

  def test_converts_multiple_values_array_picks_first_float
    assert_in_delta(7.5, Factbase::ToFloat.new([[7.5, 9.9]]).evaluate(fact, [], Factbase.new))
  end
end
