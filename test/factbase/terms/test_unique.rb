# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/unique'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for unique term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestUnique < Factbase::Test
  def test_unique
    t = Factbase::Unique.new([:foo])
    refute(t.evaluate(fact, [], Factbase.new))
    assert(t.evaluate(fact('foo' => 41), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 41), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 1), [], Factbase.new))
  end

  def test_unique_when_one_value_is_new
    t = Factbase::Unique.new([:foo])
    assert(t.evaluate(fact('foo' => [1]), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [1, 2]), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [3]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => [1, 2]), [], Factbase.new))
  end

  def test_unique_with_multiple_arguments
    t = Factbase::Term.new(:unique, %i[foo bar])
    assert(t.evaluate(fact('foo' => 1, 'bar' => 'a'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 1, 'bar' => 'b'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 2, 'bar' => 'a'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 2, 'bar' => 'b'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 1, 'bar' => 'a'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 1, 'bar' => 'b'), [], Factbase.new))
  end

  def test_unique_stops_when_all_arguments_are_duplicates
    t = Factbase::Term.new(:unique, %i[foo bar baz])
    assert(t.evaluate(fact('foo' => 1, 'bar' => 'x', 'baz' => true), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 2, 'bar' => 'x', 'baz' => false), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 1, 'bar' => 'y', 'baz' => true), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 2, 'bar' => 'x', 'baz' => true), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 1, 'bar' => 'x', 'baz' => true), [], Factbase.new))
  end

  def test_repeats_on_the_second_run
    fb = Factbase.new
    fb.insert.name = 'alice'
    fb.insert.name = 'bob'
    q = fb.query('(unique name)')
    assert_equal(2, q.each.to_a.size)
    assert_equal(2, q.each.to_a.size)
  end
end
