# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/agg'
require_relative '../../../lib/factbase/syntax'

# Test for the 'agg' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestAgg < Factbase::Test
  def test_aggregation
    maps = [
      { 'x' => [1], 'y' => [0], 'z' => [4] },
      { 'x' => [2], 'y' => [42], 'z' => [3] },
      { 'x' => [3], 'y' => [42], 'z' => [5] },
      { 'x' => [4], 'y' => [42], 'z' => [2] },
      { 'x' => [5], 'y' => [42], 'z' => [1] },
      { 'x' => [8], 'y' => [0], 'z' => [6] }
    ]
    {
      '(eq x (agg (eq y 42) (min x)))' => '(eq x 2)',
      '(eq z (agg (eq y 0) (max z)))' => '(eq x 8)',
      '(eq x (agg (and (eq y 42) (gt z 1)) (max x)))' => '(eq x 4)',
      '(and (eq x (agg (eq y 42) (min x))) (eq z 3))' => '(eq x 2)',
      '(eq x (agg (eq y 0) (nth 0 x)))' => '(eq x 1)',
      '(eq x (agg (eq y 0) (first x)))' => '(eq x 1)',
      '(agg (eq foo 42) (always))' => '(eq x 1)'
    }.each do |q, r|
      t = Factbase::Syntax.new(q).to_term
      f = maps.find { |m| t.evaluate(fact(m), maps, Factbase.new) }
      refute_nil(f, "nothing found by: #{q}")
      assert(Factbase::Syntax.new(r).to_term.evaluate(fact(f), [], Factbase.new))
    end
  end

  def test_agg_with_invalid_arguments
    assert_includes(assert_raises(RuntimeError) do
      Factbase::Agg.new(%w[foo bar baz]).evaluate(fact({}), [], Factbase.new)
    end.message, "Too many (3) operands for 'agg' (2 expected)")
    assert_includes(assert_raises(RuntimeError) do
      Factbase::Agg.new(['foo', 42]).evaluate(fact({}), [], Factbase.new)
    end.message, "A term is expected, but 'foo' provided")
    assert_includes(assert_raises(RuntimeError) do
      Factbase::Agg.new([Factbase::Term.new(:eq, ['x', 1]), 'bar']).evaluate(fact({}), [], Factbase.new)
    end.message, "A term is expected, but 'bar' provided")
  end

  def test_agg_with_correct_arguments
    t = Factbase::Agg.new([Factbase::Term.new(:eq, [:x, 42]), Factbase::Term.new(:sum, [:y])])
    maps = [
      { 'x' => [1], 'y' => [0] },
      { 'x' => [42], 'y' => [11] },
      { 'x' => [42], 'y' => [31] },
      { 'x' => [100], 'y' => [50] }
    ]
    assert_equal(42, t.evaluate(fact, maps, Factbase.new))
  end
end
