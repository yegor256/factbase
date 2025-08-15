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

  def test_unique_with_multiple_arguments
    t = Factbase::Term.new(:unique, %i[foo bar])
    assert(t.evaluate(fact('foo' => 1, 'bar' => 'a'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 1, 'bar' => 'b'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 2, 'bar' => 'a'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 1, 'bar' => 'a'), [], Factbase.new))
  end

  def test_unique_stops_when_all_arguments_are_duplicates
    t = Factbase::Term.new(:unique, %i[foo bar baz])
    assert(t.evaluate(fact('foo' => 1, 'bar' => 'x', 'baz' => true), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 2, 'bar' => 'x', 'baz' => false), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 1, 'bar' => 'y', 'baz' => true), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 1, 'bar' => 'x', 'baz' => true), [], Factbase.new))
  end
end
