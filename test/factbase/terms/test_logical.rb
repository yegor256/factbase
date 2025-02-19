# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative '../../../lib/factbase/term'

# Logical test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestLogical < Minitest::Test
  def test_not_matching
    t = Factbase::Term.new(Factbase.new, :not, [Factbase::Term.new(Factbase.new, :always, [])])
    refute(t.evaluate(fact('foo' => [100]), []))
  end

  def test_not_eq_matching
    t = Factbase::Term.new(Factbase.new, :not, [Factbase::Term.new(Factbase.new, :eq, [:foo, 100])])
    assert(t.evaluate(fact('foo' => [42, 12, -90]), []))
    refute(t.evaluate(fact('foo' => 100), []))
  end

  def test_either
    t = Factbase::Term.new(Factbase.new, :either, [Factbase::Term.new(Factbase.new, :at, [5, :foo]), 42])
    assert_equal([42], t.evaluate(fact('foo' => 4), []))
  end

  def test_or_matching
    t = Factbase::Term.new(
      Factbase.new,
      :or,
      [
        Factbase::Term.new(Factbase.new, :eq, [:foo, 4]),
        Factbase::Term.new(Factbase.new, :eq, [:bar, 5])
      ]
    )
    assert(t.evaluate(fact('foo' => [4]), []))
    assert(t.evaluate(fact('bar' => [5]), []))
    refute(t.evaluate(fact('bar' => [42]), []))
  end

  def test_when_matching
    t = Factbase::Term.new(
      Factbase.new,
      :when,
      [
        Factbase::Term.new(Factbase.new, :eq, [:foo, 4]),
        Factbase::Term.new(Factbase.new, :eq, [:bar, 5])
      ]
    )
    assert(t.evaluate(fact('foo' => 4, 'bar' => 5), []))
    refute(t.evaluate(fact('foo' => 4), []))
    assert(t.evaluate(fact('foo' => 5, 'bar' => 5), []))
  end
end
