# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Test for unique term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/unique'

class TestUnique < Factbase::Test
  def test_unique
    t = Factbase::Unique.new([:foo])
    refute(t.evaluate(fact, [], Factbase.new))
    assert(t.evaluate(fact('foo' => 41), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 41), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 1), [], Factbase.new))
    p t
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
end
