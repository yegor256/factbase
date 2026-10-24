# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/traced'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for traced term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTraced < Factbase::Test
  def test_traced
    t = Factbase::Traced.new([Factbase::Term.new(:defn, [:test_debug, 'self.to_s'])])
    assert_output("(traced (defn test_debug 'self.to_s')) -> true\n") do
      assert(t.evaluate(fact, [], Factbase.new))
    end
  end

  def test_traced_with_term_base
    t = Factbase::Traced.new([Factbase::Always.new([])])
    assert_output("(traced (always)) -> true\n") do
      assert(t.evaluate(fact, [], Factbase.new))
    end
  end

  def test_traced_with_never_term_base
    t = Factbase::Traced.new([Factbase::Never.new([])])
    assert_output("(traced (never)) -> false\n") do
      refute(t.evaluate(fact, [], Factbase.new))
    end
  end

  def test_traced_raises
    assert_match(
      /A term is expected, but 'foo' provided/,
      assert_raises(StandardError) do
        Factbase::Traced.new(['foo']).evaluate(fact, [], Factbase.new)
      end.message
    )
  end

  def test_traced_raises_when_too_many_args
    assert_match(
      /Too many \(\d+\) operands for 'traced' \(\d+ expected\)/,
      assert_raises(StandardError) do
        Factbase::Traced.new(
          [Factbase::Term.new(:defn, [:debug, 'self.to_s']), 'something']
        ).evaluate(fact, [], Factbase.new)
      end.message
    )
  end

  def test_traced_returns_false
    t = Factbase::Traced.new([Factbase::Term.new(:never, [])])
    assert_output("(traced (never)) -> false\n") do
      res = t.evaluate(fact, [], Factbase.new)
      refute(res)
      assert_instance_of(FalseClass, res)
    end
  end

  def test_traced_returns_nil
    t = Factbase::Traced.new([Factbase::Term.new(:prev, [:x])])
    assert_output("(traced (prev x)) -> \n") do
      assert_nil(t.evaluate(fact, [], Factbase.new))
    end
  end

  def test_traced_returns_integer
    t = Factbase::Traced.new([Factbase::Term.new(:to_integer, ['42'])])
    assert_output("(traced (to_integer '42')) -> 42\n") do
      res = t.evaluate(fact, [], Factbase.new)
      assert_instance_of(Integer, res)
      assert_equal(42, res)
    end
  end

  def test_traced_returns_float
    t = Factbase::Traced.new([Factbase::Term.new(:to_float, ['3.14'])])
    assert_output("(traced (to_float '3.14')) -> 3.14\n") do
      res = t.evaluate(fact, [], Factbase.new)
      assert_instance_of(Float, res)
      assert_in_delta(3.14, res)
    end
  end

  def test_traced_returns_string
    t = Factbase::Traced.new([Factbase::Term.new(:to_string, [42])])
    assert_output("(traced (to_string 42)) -> 42\n") do
      res = t.evaluate(fact, [], Factbase.new)
      assert_instance_of(String, res)
      assert_equal('42', res)
    end
  end

  def test_traced_returns_boolean
    t_true = Factbase::Traced.new([Factbase::Term.new(:always, [])])
    assert_output("(traced (always)) -> true\n") do
      res = t_true.evaluate(fact, [], Factbase.new)
      assert(res)
      assert_instance_of(TrueClass, res)
    end
    t_false = Factbase::Traced.new([Factbase::Term.new(:never, [])])
    assert_output("(traced (never)) -> false\n") do
      res = t_false.evaluate(fact, [], Factbase.new)
      refute(res)
      assert_instance_of(FalseClass, res)
    end
  end

  def test_traced_false_in_query_does_not_match
    fb = Factbase.new
    fb.insert.x = 42
    assert_output("(traced (eq x 99)) -> false\n") do
      assert_empty(fb.query('(traced (eq x 99))').each.to_a)
    end
  end

  def test_traced_query_filters_matching_facts
    fb = Factbase.new
    fb.insert.x = 42
    fb.insert.x = 99
    assert_output("(traced (eq x 99)) -> false\n(traced (eq x 99)) -> true\n") do
      matched = fb.query('(traced (eq x 99))').each.to_a
      assert_equal(1, matched.size)
      assert_equal(99, matched[0].x)
    end
  end
end
