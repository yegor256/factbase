# frozen_string_literal: true

require_relative '../../../lib/factbase/terms/boolean'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for the 'boolean'.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestBoolean < Factbase::Test
  def test_any_element
    assert_predicate(Factbase::Boolean.new([true, false], 'test_source'), :bool?)
  end

  def test_any_element_when_true_is_not_first
    assert_predicate(Factbase::Boolean.new([false, true], 'test_source'), :bool?)
  end

  def test_no_true_element
    refute_predicate(Factbase::Boolean.new([false, false], 'test_source'), :bool?)
  end

  def test_every_element
    assert_predicate(Factbase::Boolean.new([true, true], 'test_source'), :every?)
  end

  def test_not_every_element
    refute_predicate(Factbase::Boolean.new([false, true], 'test_source'), :every?)
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
end
