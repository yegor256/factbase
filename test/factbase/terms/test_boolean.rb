# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/terms/boolean'

require_relative '../../test__helper'

# Test for the 'boolean'.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestBoolean < Factbase::Test
  def test_first_element
    assert_predicate(Factbase::Boolean.new([true, false], 'test_source'), :bool?)
  end

  def test_first_element_false
    refute_predicate(Factbase::Boolean.new([false, true], 'test_source'), :bool?)
  end

  def test_direct_true
    assert_predicate(Factbase::Boolean.new(true, 'test_source'), :bool?)
  end

  def test_direct_false
    refute_predicate(Factbase::Boolean.new(false, 'test_source'), :bool?)
  end

  def test_nil_value
    refute_predicate(Factbase::Boolean.new(nil, 'test_source'), :bool?)
  end

  def test_invalid_value
    b = Factbase::Boolean.new(42, 'test_source')
    assert_includes(
      assert_raises(StandardError) do
        b.bool?
      end.message, 'Boolean is expected, while Integer received from test_source'
    )
  end

  def test_hash_value_raises_argument_error
    b = Factbase::Boolean.new({ foo: 'bar' }, 'test_source')
    assert_includes(
      assert_raises(ArgumentError) { b.bool? }.message,
      'Boolean is expected, while Hash received from test_source'
    )
  end

  def test_hash_with_integer_key_raises_argument_error
    b = Factbase::Boolean.new({ 0 => true }, 'test_source')
    assert_includes(
      assert_raises(ArgumentError) { b.bool? }.message,
      'Boolean is expected, while Hash received from test_source'
    )
  end

  def test_empty_hash_raises_argument_error
    b = Factbase::Boolean.new({}, 'test_source')
    assert_includes(
      assert_raises(ArgumentError) { b.bool? }.message,
      'Boolean is expected, while Hash received from test_source'
    )
  end

  def test_string_value_raises_argument_error
    b = Factbase::Boolean.new('true', 'test_source')
    assert_includes(
      assert_raises(ArgumentError) { b.bool? }.message,
      'Boolean is expected, while String received from test_source'
    )
  end

  def test_float_value_raises_argument_error
    b = Factbase::Boolean.new(3.14, 'test_source')
    assert_includes(
      assert_raises(ArgumentError) { b.bool? }.message,
      'Boolean is expected, while Float received from test_source'
    )
  end

  def test_symbol_value_raises_argument_error
    b = Factbase::Boolean.new(:active, 'test_source')
    assert_includes(
      assert_raises(ArgumentError) { b.bool? }.message,
      'Boolean is expected, while Symbol received from test_source'
    )
  end

  def test_array_containing_hash_raises_argument_error
    b = Factbase::Boolean.new([{ enabled: true }], 'test_source')
    assert_includes(
      assert_raises(ArgumentError) { b.bool? }.message,
      'Boolean is expected, while Hash received from test_source'
    )
  end

  def test_empty_array_returns_false
    refute_predicate(Factbase::Boolean.new([], 'test_source'), :bool?)
  end
end
