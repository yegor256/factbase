# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/syntax'

# Aggregates test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestAggregates < Minitest::Test
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
      t = Factbase::Syntax.new(Factbase.new, q).to_term
      f = maps.find { |m| t.evaluate(fact(m), maps) }
      refute_nil(f, "nothing found by: #{q}")
      assert(Factbase::Syntax.new(Factbase.new, r).to_term.evaluate(fact(f), []))
    end
  end

  def test_empty
    maps = [
      { 'x' => [1], 'y' => [0], 'z' => [4] },
      { 'x' => [8], 'y' => [0] }
    ]
    {
      '(empty (eq y 42))' => true,
      '(empty (eq x 1))' => false
    }.each do |q, r|
      t = Factbase::Syntax.new(Factbase.new, q).to_term
      assert_equal(r, t.evaluate(nil, maps), q)
    end
  end
end
