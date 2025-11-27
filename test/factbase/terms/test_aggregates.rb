# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/syntax'

# Aggregates test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestAggregates < Factbase::Test
  def test_empty
    maps = [
      { 'x' => [1], 'y' => [0], 'z' => [4] },
      { 'x' => [8], 'y' => [0] }
    ]
    {
      '(empty (eq y 42))' => true,
      '(empty (eq x 1))' => false
    }.each do |q, r|
      t = Factbase::Syntax.new(q).to_term
      assert_equal(r, t.evaluate(Factbase::Fact.new({}), maps, Factbase.new), q)
    end
  end

  def test_empty_with_params
    maps = [
      { 'a' => [3], 'b' => [44] },
      { 'a' => [4], 'b' => [55] }
    ]
    t = Factbase::Syntax.new('(empty (eq b $_x))').to_term
    assert(t.evaluate(Factbase::Fact.new({ '_x' => [42] }), maps, Factbase.new))
    refute(t.evaluate(Factbase::Fact.new({ '_x' => [44] }), maps, Factbase.new))
  end
end
