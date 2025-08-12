# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'

# Ordering test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestOrdering < Factbase::Test
  def test_prev
    t = Factbase::Term.new(:prev, [:foo])
    assert_nil(t.evaluate(fact('foo' => 41), [], Factbase.new))
    assert_equal([41], t.evaluate(fact('foo' => 5), [], Factbase.new))
    assert_equal([5], t.evaluate(fact('foo' => 6), [], Factbase.new))
  end

  def test_unique
    t = Factbase::Term.new(:unique, [:foo])
    refute(t.evaluate(fact, [], Factbase.new))
    assert(t.evaluate(fact('foo' => 41), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 41), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 1), [], Factbase.new))
  end

  def test_unique_with_array
    t = Factbase::Term.new(:unique, [:foo])
    refute(t.evaluate(fact, [], Factbase.new))
    assert(t.evaluate(fact('foo' => [1, 2]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => [2, 3]), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [4, 5]), [], Factbase.new))
  end

  def test_unique_performance
    t = Factbase::Term.new(:unique, [:id])
    n = 10_000
    u = 0
    n.times.map do |i|
      u += 1 if t.evaluate(fact('id' => i % 100), [], Factbase.new)
    end
    assert_equal 100, u
  end
end
