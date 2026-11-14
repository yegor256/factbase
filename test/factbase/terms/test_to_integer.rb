# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_integer'

require_relative '../../test__helper'

# Test for 'to_integer' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToInteger < Factbase::Test
  def test_to_integer
    assert_equal('Integer', Factbase::ToInteger.new([[42, 'hello']]).evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_truncates_float
    assert_equal(5_961_600, Factbase::ToInteger.new([[5_961_600.7]]).evaluate(fact, [], Factbase.new))
  end

  def test_truncates_positive_float_with_fraction
    assert_equal(1, Factbase::ToInteger.new([[1.9]]).evaluate(fact, [], Factbase.new))
  end

  def test_truncates_negative_float_with_fraction
    assert_equal(-1, Factbase::ToInteger.new([[-1.9]]).evaluate(fact, [], Factbase.new))
  end

  def test_truncates_positive_float_near_one
    assert_equal(0, Factbase::ToInteger.new([[0.9999]]).evaluate(fact, [], Factbase.new))
  end

  def test_truncates_negative_float_near_minus_one
    assert_equal(0, Factbase::ToInteger.new([[-0.9999]]).evaluate(fact, [], Factbase.new))
  end

  def test_truncates_positive_float_forty_two
    assert_equal(42, Factbase::ToInteger.new([[42.7]]).evaluate(fact, [], Factbase.new))
  end

  def test_truncates_negative_float_forty_two
    assert_equal(-42, Factbase::ToInteger.new([[-42.7]]).evaluate(fact, [], Factbase.new))
  end

  def test_truncates_positive_float_near_zero
    assert_equal(0, Factbase::ToInteger.new([[0.1]]).evaluate(fact, [], Factbase.new))
  end

  def test_truncates_negative_float_near_zero
    assert_equal(0, Factbase::ToInteger.new([[-0.1]]).evaluate(fact, [], Factbase.new))
  end

  def test_truncates_positive_float_with_query
    fb = Factbase.new
    fb.insert.f = 1.9
    assert_equal([1], fb.query('(as r (to_integer f))').each.to_a.first['r'])
  end

  def test_truncates_negative_float_with_query
    fb = Factbase.new
    fb.insert.f = -1.9
    assert_equal([-1], fb.query('(as r (to_integer f))').each.to_a.first['r'])
  end

  def test_truncates_float_near_one_with_query
    fb = Factbase.new
    fb.insert.f = 0.9999
    assert_equal([0], fb.query('(as r (to_integer f))').each.to_a.first['r'])
  end

  def test_truncates_negative_float_near_minus_one_with_query
    fb = Factbase.new
    fb.insert.f = -0.9999
    assert_equal([0], fb.query('(as r (to_integer f))').each.to_a.first['r'])
  end

  def test_truncates_float_forty_two_with_query
    fb = Factbase.new
    fb.insert.f = 42.7
    assert_equal([42], fb.query('(as r (to_integer f))').each.to_a.first['r'])
  end

  def test_truncates_negative_float_forty_two_with_query
    fb = Factbase.new
    fb.insert.f = -42.7
    assert_equal([-42], fb.query('(as r (to_integer f))').each.to_a.first['r'])
  end

  def test_rejects_invalid_value
    assert_includes(
      assert_raises(RuntimeError) { Factbase::ToInteger.new(['abc']).evaluate(fact, [], Factbase.new) }.message,
      "Cannot convert 'abc' to Integer in (to_integer ...):"
    )
  end

  def test_converts_boolean_true_to_one
    assert_equal(1, Factbase::ToInteger.new([[true]]).evaluate(fact, [], Factbase.new))
  end

  def test_converts_boolean_false_to_zero
    assert_equal(0, Factbase::ToInteger.new([[false]]).evaluate(fact, [], Factbase.new))
  end

  def test_returns_nil_for_empty_operand_array
    assert_nil(Factbase::ToInteger.new([[]]).evaluate(fact, [], Factbase.new))
  end

  def test_returns_nil_for_absent_property
    assert_nil(Factbase::ToInteger.new([:non_existent]).evaluate(fact, [], Factbase.new))
  end

  def test_converts_boolean_in_query
    fb = Factbase.new
    f = fb.insert
    f.active = true
    f.deleted = false
    assert_equal(1, fb.query('(eq 1 (to_integer active))').each.to_a.size)
    assert_equal(1, fb.query('(eq 0 (to_integer deleted))').each.to_a.size)
  end

  def test_converts_comparison_result_to_integer
    fb = Factbase.new
    fb.insert.score = 50
    assert_equal(1, fb.query('(eq 1 (to_integer (gt score 10)))').each.to_a.size)
    assert_equal(1, fb.query('(eq 0 (to_integer (lt score 10)))').each.to_a.size)
  end

  def test_converts_string_digits_to_integer
    assert_equal(123, Factbase::ToInteger.new([['123']]).evaluate(fact, [], Factbase.new))
  end

  def test_converts_negative_string_to_integer
    assert_equal(-42, Factbase::ToInteger.new([['-42']]).evaluate(fact, [], Factbase.new))
  end

  def test_converts_zero_integer
    assert_equal(0, Factbase::ToInteger.new([[0]]).evaluate(fact, [], Factbase.new))
  end

  def test_converts_positive_integer_directly
    assert_equal(100, Factbase::ToInteger.new([[100]]).evaluate(fact, [], Factbase.new))
  end
end
