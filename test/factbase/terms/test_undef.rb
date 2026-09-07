# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/defn'
require_relative '../../../lib/factbase/terms/undef'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for undef term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestUndef < Factbase::Test
  def test_undef_simple
    t = Factbase::Defn.new([:hello, 'self.to_s'])
    assert(t.evaluate(fact, [], Factbase.new))
    t = Factbase::Undef.new([:hello])
    assert(t.evaluate(fact, [], Factbase.new))
  end

  def test_undef_nonexistent
    assert(Factbase::Undef.new([:_nonexistent]).evaluate(fact, [], Factbase.new))
  end

  def test_undef_non_symbol
    assert_raises(ArgumentError) do
      Factbase::Undef.new(['string']).evaluate(fact, [], Factbase.new)
    end
  end

  def test_undef_defined_then_removed
    fn = :_undef_query_fn
    Factbase::Undef.new([fn]).evaluate(fact, [], Factbase.new)
    Factbase::Defn.new([fn, 'true']).evaluate(fact, [], Factbase.new)
    assert(Factbase::Term.new(fn, []).evaluate(fact, [], Factbase.new))
    Factbase::Undef.new([fn]).evaluate(fact, [], Factbase.new)
    assert_raises(RuntimeError) do
      Factbase::Term.new(fn, []).evaluate(fact, [], Factbase.new)
    end
  end

  def test_refuses_to_undefine_a_class_based_term
    fb = Factbase.new
    fb.insert.foo = 42
    e = assert_raises(StandardError) { fb.query('(undef eq)').each.to_a }
    assert_includes(e.message, "Term 'eq' is built-in and cannot be undefined", e.message)
    assert_equal(1, fb.query('(eq foo 42)').each.to_a.size)
  end
end
