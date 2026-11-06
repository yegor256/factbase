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
    t = Factbase::ToInteger.new(['abc'])
    assert_includes(
      assert_raises(RuntimeError) { t.evaluate(fact, [], Factbase.new) }.message,
      "Cannot convert 'abc' to Integer in (to_integer ...):"
    )
  end
end
