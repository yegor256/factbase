# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/defn'
require_relative '../../../lib/factbase/terms/undef'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for defn term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestDefn < Factbase::Test
  def setup
    super
    @defn_name = :_defn_teardown
    Factbase::Undef.new([@defn_name]).evaluate(fact, [], Factbase.new)
  end

  def teardown
    Factbase::Undef.new([@defn_name]).evaluate(fact, [], Factbase.new)
    super
  end

  def test_defn_simple
    assert(Factbase::Defn.new([:foo, 'self.to_s']).evaluate(fact('foo' => 4), [], Factbase.new))
    assert_equal(
      '(foo \'hello, world!\')',
      Factbase::Term.new(:foo, ['hello, world!']).evaluate(fact, [], Factbase.new)
    )
  end

  def test_defn_again_by_mistake
    t = Factbase::Defn.new([:unexisting_function, 'self.to_s'])
    t.evaluate(fact, [], Factbase.new)
    assert_raises(StandardError) do
      t.evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_bad_name_by_mistake
    t = Factbase::Defn.new([:to_s, 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_bad_name_spelling_by_mistake
    t = Factbase::Defn.new([:'some-key', 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_bad_name_with_digits
    assert_includes(
      assert_raises(ArgumentError) do
        Factbase::Defn.new([:'123abc', 'true']).evaluate(fact, [], Factbase.new)
      end.message,
      'must match /\A[_a-z][a-zA-Z0-9_]*\z/'
    )
  end

  def test_defn_bad_name_with_caps
    assert_includes(
      assert_raises(ArgumentError) do
        Factbase::Defn.new([:FooBar, 'true']).evaluate(fact, [], Factbase.new)
      end.message,
      'must match /\A[_a-z][a-zA-Z0-9_]*\z/'
    )
  end

  def test_defn_with_digits
    n = :is_ok2
    Factbase::Undef.new([n]).evaluate(fact, [], Factbase.new)
    fb = Factbase.new
    f1 = fb.insert
    f1.foo = 42
    f2 = fb.insert
    f2.foo = 20
    assert(Factbase::Defn.new([n, 'fact.foo == 42']).evaluate(f1, [], fb))
    assert(Factbase::Term.new(n, []).evaluate(f1, [], fb))
    refute(Factbase::Term.new(n, []).evaluate(f2, [], fb))
    assert_equal(1, fb.query("(#{n})").each.to_a.size)
  ensure
    Factbase::Undef.new([n]).evaluate(fact, [], Factbase.new)
  end

  def test_defn_with_camel_case
    n = :isOk
    Factbase::Undef.new([n]).evaluate(fact, [], Factbase.new)
    fb = Factbase.new
    f1 = fb.insert
    f1.bar = 100
    f2 = fb.insert
    f2.bar = 10
    assert(Factbase::Defn.new([n, 'fact.bar > 50']).evaluate(f1, [], fb))
    assert(Factbase::Term.new(n, []).evaluate(f1, [], fb))
    refute(Factbase::Term.new(n, []).evaluate(f2, [], fb))
    assert_equal(1, fb.query("(#{n})").each.to_a.size)
  ensure
    Factbase::Undef.new([n]).evaluate(fact, [], Factbase.new)
  end

  def test_defn_with_leading_underscore
    n = :_foo
    Factbase::Undef.new([n]).evaluate(fact, [], Factbase.new)
    fb = Factbase.new
    f1 = fb.insert
    f1.msg = 'hello'
    f2 = fb.insert
    f2.msg = 'world'
    assert(Factbase::Defn.new([n, "fact.msg == 'hello'"]).evaluate(f1, [], fb))
    assert(Factbase::Term.new(n, []).evaluate(f1, [], fb))
    refute(Factbase::Term.new(n, []).evaluate(f2, [], fb))
    assert_equal(1, fb.query("(#{n})").each.to_a.size)
  ensure
    Factbase::Undef.new([n]).evaluate(fact, [], Factbase.new)
  end

  def test_defn_defined_and_queried_via_syntax
    fb = Factbase.new
    fb.insert.v = 42
    fb.insert.v = 15
    assert_equal(1, fb.query('(and (undef is_ok2) (defn is_ok2 "fact.v == 42") (is_ok2))').each.to_a.size)
    assert_equal(1, fb.query('(and (undef isOk) (defn isOk "fact.v > 20") (isOk))').each.to_a.size)
    assert_equal(1, fb.query('(and (undef _foo) (defn _foo "fact.v == 15") (_foo))').each.to_a.size)
  ensure
    Factbase::Undef.new([:is_ok2]).evaluate(fact, [], Factbase.new)
    Factbase::Undef.new([:isOk]).evaluate(fact, [], Factbase.new)
    Factbase::Undef.new([:_foo]).evaluate(fact, [], Factbase.new)
  end

  def test_defn_eval_arbitrary_code
    n = :_defn_eval_z
    Factbase::Undef.new([n]).evaluate(fact, [], Factbase.new)
    Factbase::Defn.new([n, '42']).evaluate(fact, [], Factbase.new)
    assert_equal(42, Factbase::Term.new(n, []).evaluate(fact, [], Factbase.new))
  end

  def test_defn_undef_then_use
    n = @defn_name
    Factbase::Defn.new([n, 'true']).evaluate(fact, [], Factbase.new)
    Factbase::Undef.new([n]).evaluate(fact, [], Factbase.new)
    assert_raises(RuntimeError) do
      Factbase::Term.new(n, []).evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_with_simplify_suffix_does_not_break_other_term
    n = @defn_name
    s = :"#{n}_simplify"
    Factbase::Defn.new([n, 'true']).evaluate(fact, [], Factbase.new)
    Factbase::Defn.new([s, 'true']).evaluate(fact, [], Factbase.new)
    fb = Factbase.new
    fb.insert.x = 1
    assert_equal(1, fb.query("(#{n})").each.to_a.size)
  ensure
    Factbase::Undef.new([s]).evaluate(fact, [], Factbase.new)
  end

  def test_defn_non_symbol_argument
    assert_raises(ArgumentError) do
      Factbase::Defn.new(%w[string_name true]).evaluate(fact, [], Factbase.new)
    end
  end

  def test_refuses_to_redefine_a_class_based_term
    fb = Factbase.new
    fb.insert.foo = 42
    e = assert_raises(StandardError) { fb.query('(defn eq "false")').each.to_a }
    assert_includes(e.message, "Term 'eq' is already defined", e.message)
  end

  def test_defines_term_once_for_each_fact_in_a_query
    n = :_defn_multiple_facts
    Factbase::Undef.new([n]).evaluate(fact, [], Factbase.new)
    fb = Factbase.new
    fb.insert.id = 1
    fb.insert.id = 2
    assert_equal([1, 2], fb.query("(defn #{n} 'true')").each.map { |item| item['id'].first })
    Factbase::Undef.new([n]).evaluate(fact, [], Factbase.new)
  end

  def test_defines_the_term_again_after_undef
    fb = Factbase.new
    3.times { |i| fb.insert.x = i }
    n = @defn_name
    assert_equal(3, fb.query("(and (undef #{n}) (defn #{n} \"true\") (#{n}))").each.to_a.size)
  end

  def test_refuses_to_redefine_an_inherited_private_helper
    fb = Factbase.new
    fb.insert.foo = 42
    e = assert_raises(StandardError) { fb.query('(defn _values "999")').each.to_a }
    assert_includes(e.message, "Term '_values' is already defined", e.message)
    assert_equal(1, fb.query('(eq foo (at 0 foo))').each.to_a.size)
  end

  def test_refuses_a_name_that_kernel_keeps_private
    fb = Factbase.new
    fb.insert.foo = 42
    e = assert_raises(StandardError) { fb.query('(defn warn "999")').each.to_a }
    assert_includes(e.message, "Term 'warn' is already defined", e.message)
  end
end
