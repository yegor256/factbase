# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/defn'
require_relative '../../../lib/factbase/terms/undef'

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
    assert_raises(StandardError) do
      Factbase::Defn.new([:'123abc', 'true']).evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_bad_name_with_caps
    assert_raises(StandardError) do
      Factbase::Defn.new([:FooBar, 'true']).evaluate(fact, [], Factbase.new)
    end
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

  def test_defn_refuses_multiline_symbol_name
    assert_raises(ArgumentError) do
      Factbase::Defn.new([:"_bad_multiline_probe\n#", 'true']).evaluate(fact, [], Factbase.new)
    end
    refute(Factbase::Term.private_method_defined?(:_bad_multiline_probe, false))
  end

  def test_defn_refuses_trailing_newline_in_symbol_name
    assert_raises(ArgumentError) do
      Factbase::Defn.new([:"_trailing_probe\n", 'true']).evaluate(fact, [], Factbase.new)
    end
    refute(Factbase::Term.private_method_defined?(:_trailing_probe, false))
  end

  def test_defn_refuses_leading_newline_in_symbol_name
    assert_raises(ArgumentError) do
      Factbase::Defn.new([:"\n_leading_probe", 'true']).evaluate(fact, [], Factbase.new)
    end
    refute(Factbase::Term.private_method_defined?(:_leading_probe, false))
  end

  def test_defn_refuses_carriage_return_in_symbol_name
    assert_raises(ArgumentError) do
      Factbase::Defn.new([:"_carriage_return_probe\r#", 'true']).evaluate(fact, [], Factbase.new)
    end
    refute(Factbase::Term.private_method_defined?(:_carriage_return_probe, false))
  end

  def test_defn_refuses_embedded_newline_in_symbol_name
    assert_raises(ArgumentError) do
      Factbase::Defn.new([:"first_part\nsecond_part", 'true']).evaluate(fact, [], Factbase.new)
    end
    refute(Factbase::Term.private_method_defined?(:first_part, false))
    refute(Factbase::Term.private_method_defined?(:second_part, false))
  end

  def test_defn_refuses_multiline_symbol_in_query
    fb = Factbase.new
    fb.insert.id = 1
    term = Factbase::Term.new(:defn, [:"_bad_query_probe\n#", 'true'])
    assert_raises(StandardError) do
      fb.query(term).each.to_a
    end
    refute(Factbase::Term.private_method_defined?(:_bad_query_probe, false))
  end
end
