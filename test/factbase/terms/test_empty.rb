# frozen_string_literal: true

require_relative '../../../lib/factbase/syntax'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/empty'
require_relative '../../../lib/factbase/terms/gt'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
require_relative '../../test__helper'

# Tests for the 'empty' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestEmpty < Factbase::Test
  def test_empty_query
    maps = [{ 'x' => [1], 'y' => [0], 'z' => [4] }, { 'x' => [8], 'y' => [0] }]
    {
      '(empty (eq y 42))' => true,
      '(empty (eq x 1))' => false
    }.each do |q, r|
      assert_equal(r, Factbase::Syntax.new(q).to_term.evaluate(Factbase::Fact.new({}), maps, Factbase.new), q)
    end
  end

  def test_empty_query_with_params
    maps = [{ 'a' => [3], 'b' => [44] }, { 'a' => [4], 'b' => [55] }]
    t = Factbase::Syntax.new('(empty (eq b $_x))').to_term
    assert(t.evaluate(Factbase::Fact.new({ '_x' => [42] }), maps, Factbase.new))
    refute(t.evaluate(Factbase::Fact.new({ '_x' => [44] }), maps, Factbase.new))
  end

  def test_empty_wrong_arguments
    t = Factbase::Empty.new([])
    assert_equal(
      "Too few (0) operands for 'empty' (1 expected)",
      assert_raises(StandardError) do
        t.evaluate(Factbase::Fact.new({}), [], Factbase.new)
      end.message
    )
  end

  def test_empty_directly_with_terms
    assert(
      Factbase::Empty.new([Factbase::Term.new(:gt, [:number, 10])]).evaluate(
        fact,
        [{ 'number' => [10] }, { 'number' => [9] }, { 'number' => [5] }], Factbase.new
      )
    )
  end

  def test_not_empty_directly_with_terms
    refute(
      Factbase::Empty.new([Factbase::Term.new(:gt, [:number, 10])]).evaluate(
        fact,
        [{ 'number' => [11] }, { 'number' => [9] }, { 'number' => [5] }], Factbase.new
      )
    )
  end
end
