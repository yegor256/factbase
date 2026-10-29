# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/always'
require_relative '../../../lib/factbase/terms/never'
require_relative '../../../lib/factbase/terms/or'
require_relative '../../../lib/factbase/terms/simplified'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'benchmark'
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

  def test_performance_with_large_operands
    ops = (1..2_000).map { |i| Factbase::Term.new(:eq, [:x, i]) }
    assert_operator(
      Benchmark.realtime do
        assert_equal(ops.size, Factbase::Simplified.new(ops).unique.size)
      end,
      :<,
      1.0
    )
  end

  def test_performance_simplifying_long_or
    ops = (1..2_000).map { |i| Factbase::Term.new(:eq, [:x, i]) }
    assert_operator(
      Benchmark.realtime do
        assert_equal(ops.size, Factbase::Or.new(ops).simplify.operands.size)
      end,
      :<,
      1.0
    )
  end
end
