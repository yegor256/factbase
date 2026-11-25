# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/always'
require_relative '../../../lib/factbase/terms/never'
require_relative '../../../lib/factbase/terms/or'
require_relative '../../../lib/factbase/terms/simplified'

require_relative '../../test__helper'

# Test for the 'Simplified' class.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSimplified < Factbase::Test
  def test_keeps_repeated_conditional_writes
    fb = Factbase.new
    fb.insert.x = 1
    assert_equal(
      [[1, 1]],
      fb.query('(and (when (always) (as y 1)) (when (always) (as y 1)))').each.map { |fact| fact['y'] }
    )
  end

  def test_keeps_writes_inside_nested_conditions
    fb = Factbase.new
    fb.insert.x = 1
    operand = '(when (always) (when (always) (as y 1)))'
    assert_equal([[1, 1]], fb.query("(and #{operand} #{operand})").each.map { |fact| fact['y'] })
  end

  def test_unique_operands_simple
    assert_equal(1, Factbase::Simplified.new([Factbase::Or.new([]), Factbase::Or.new([])]).unique.size)
  end

  def test_unique_operands_complex
    assert_equal(
      3,
      Factbase::Simplified.new(
        [
          Factbase::Or.new([Factbase::And.new([]), Factbase::And.new([])]),
          Factbase::Or.new([Factbase::Or.new([]), Factbase::And.new([])]), Factbase::Or.new([Factbase::Or.new([]), Factbase::Or.new([])])
        ]
      ).unique.size
    )
  end

  def test_keeps_a_repeated_as
    fb = Factbase.new
    fb.insert.x = 1
    assert_equal([[1, 1]], fb.query('(and (as y x) (as y x))').each.map { |f| f['y'] })
  end

  def test_keeps_a_repeated_unique
    fb = Factbase.new
    [1, 2].each do |y|
      f = fb.insert
      f.x = 5
      f.y = y
    end
    assert_equal([1, 2], fb.query('(or (unique x) (eq y 1) (unique x))').each.map(&:y))
  end

  def test_keeps_a_repeated_operand_with_a_nested_unique
    fb = Factbase.new
    [1, 2].each do |y|
      f = fb.insert
      f.x = 5
      f.y = y
    end
    assert_equal([1, 2], fb.query('(or (not (not (unique x))) (eq y 1) (not (not (unique x))))').each.map(&:y))
  end

  def test_preserves_distinct_types_with_same_string_representation
    assert_equal(2, Factbase::Simplified.new([false, 'false']).unique.size)
    assert_equal(2, Factbase::Simplified.new([:x, 'x']).unique.size)
    assert_equal(2, Factbase::Simplified.new([true, 'true']).unique.size)
    assert_equal(2, Factbase::Simplified.new([1, '1']).unique.size)
    assert_equal(2, Factbase::Simplified.new([Factbase::Or.new([]), '(or)']).unique.size)
  end

  def test_query_with_boolean_and_string_literal_raises_error
    fb = Factbase.new
    fb.insert.x = 1
    assert_includes(
      assert_raises(Factbase::Term::Wrapped) { fb.query("(or false 'false')").each.to_a }.message,
      'Boolean is expected, while String received'
    )
    assert_includes(
      assert_raises(Factbase::Term::Wrapped) { fb.query("(and true 'true')").each.to_a }.message,
      'Boolean is expected, while String received'
    )
  end
end
