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

  def test_unique_operands_all_distinct
    ops = [Factbase::Term.new(:eq, [:x, 1]), Factbase::Term.new(:eq, [:x, 2])]
    assert_equal(ops, Factbase::Simplified.new(ops).unique)
  end

  def test_unique_operands_deduplication
    first = Factbase::Term.new(:eq, [:x, 1])
    second = Factbase::Term.new(:eq, [:x, 2])
    third = Factbase::Term.new(:eq, [:x, 3])
    assert_equal(
      [first, second, third],
      Factbase::Simplified.new([first, second, first, third, second, first]).unique
    )
  end

  def test_unique_primitive_operands
    assert_equal(['foo', :bar, 42, 'baz'], Factbase::Simplified.new(['foo', :bar, 42, 'foo', :bar, 42, 'baz']).unique)
  end

  def test_keeps_a_repeated_join
    join = Factbase::Term.new(:join, %i[foo bar])
    assert_equal(2, Factbase::Simplified.new([join, join]).unique.size)
  end

  def test_avoids_quadratic_lookups_for_distinct_operands
    [200, 400].each do |count|
      comparisons = 0
      assert_equal(count, Factbase::Simplified.new(tracked_operands(count) { comparisons += 1 }).unique.size)
      assert_operator(comparisons, :<=, count)
    end
  end

  def test_simplifying_long_or_avoids_quadratic_lookups
    [200, 400].each do |count|
      comparisons = 0
      assert_equal(count, Factbase::Or.new(tracked_operands(count) { comparisons += 1 }).simplify.operands.size)
      assert_operator(comparisons, :<=, count)
    end
  end

  private

  def tracked_operands(count, &)
    klass =
      Class.new(String) do
        define_method(:==) do |other|
          yield
          super(other)
        end
        define_method(:eql?) do |other|
          yield
          super(other)
        end
      end
    (1..count).map do |i|
      term = Factbase::Term.new(:eq, [:x, i])
      text = klass.new(term.to_s)
      term.define_singleton_method(:to_s) { text }
      term
    end
  end
end
