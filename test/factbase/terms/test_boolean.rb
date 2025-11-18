# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/terms/boolean'

# Test for the 'boolean'.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestBoolean < Factbase::Test
  def test_first_element
    b = Factbase::Boolean.new([true, false], 'test_source')
    assert_predicate(b, :bool?)
  end

  def test_first_element_false
    b = Factbase::Boolean.new([false, true], 'test_source')
    refute_predicate(b, :bool?)
  end

  def test_direct_true
    b = Factbase::Boolean.new(true, 'test_source')
    assert_predicate(b, :bool?)
  end

  def test_direct_false
    b = Factbase::Boolean.new(false, 'test_source')
    refute_predicate(b, :bool?)
  end

  def test_nil_value
    b = Factbase::Boolean.new(nil, 'test_source')
    refute_predicate(b, :bool?)
  end

  def test_invalid_value
    b = Factbase::Boolean.new(42, 'test_source')
    error = assert_raises(RuntimeError) { b.bool? }
    assert_includes(error.message, 'Boolean is expected, while Integer received from test_source')
  end
end
