# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/cached/cached_factbase'
require_relative '../test__helper'

# Term operands test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTermOperands < Factbase::Test
  def test_ignores_later_edits_of_the_supplied_array
    ops = [:foo, 42]
    t = Factbase::Term.new(:eq, ops)
    assert_equal('(eq foo 42)', t.to_s)
    ops[1] = 43
    assert_equal('(eq foo 42)', t.to_s)
    assert(t.evaluate(fact('foo' => 42), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 43), [], Factbase.new))
  end

  def test_refuses_edits_through_the_operands_reader
    t = Factbase::Term.new(:eq, [:foo, 42])
    assert_predicate(t.operands, :frozen?)
    assert_raises(FrozenError) { t.operands[1] = 43 }
    assert(t.evaluate(fact('foo' => 42), [], Factbase.new))
    assert_equal('(eq foo 42)', Factbase::Term.new(:eq, [:foo, 42].freeze).to_s)
  end

  def test_cached_and_plain_agree_after_an_edit_attempt
    ops = [:foo, 42]
    t = Factbase::Term.new(:eq, ops)
    origin = Factbase.new
    origin.insert.foo = 42
    cached = Factbase::CachedFactbase.new(origin)
    assert_equal(1, cached.query(t).each.to_a.size)
    ops[1] = 43
    plain = origin.query(t).each.to_a.size
    assert_equal(1, plain)
    assert_equal(plain, cached.query(t).each.to_a.size)
  end

  def test_ignores_later_edits_of_a_string_operand
    str = +'hello'
    t = Factbase::Term.new(:eq, [:foo, str])
    assert_equal("(eq foo 'hello')", t.to_s)
    str << '!'
    assert_equal("(eq foo 'hello')", t.to_s)
    assert(t.evaluate(fact('foo' => 'hello'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 'hello!'), [], Factbase.new))
  end
end
