# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'

# Debug test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestDebug < Factbase::Test
  def test_traced
    t = Factbase::Term.new(:traced, [Factbase::Term.new(:defn, [:test_debug, 'self.to_s'])])
    assert_output("(traced (defn test_debug 'self.to_s')) -> true\n") do
      assert(t.evaluate(fact, [], Factbase.new))
    end
  end

  def test_traced_raises
    e = assert_raises(StandardError) { Factbase::Term.new(:traced, ['foo']).evaluate(fact, [], Factbase.new) }
    assert_match(/A term is expected, but 'foo' provided/, e.message)
  end

  def test_traced_raises_when_too_many_args
    e =
      assert_raises(StandardError) do
        Factbase::Term.new(
          :traced,
          [Factbase::Term.new(:defn, [:debug, 'self.to_s']), 'something']
        ).evaluate(fact, [], Factbase.new)
      end
    assert_match(/Too many \(\d+\) operands for 'traced' \(\d+ expected\)/, e.message)
  end

  def test_assert_with_true_condition
    t = Factbase::Term.new(:assert, ['all must be positive', Factbase::Term.new(:gt, [:foo, 0])])
    assert(t.evaluate(fact('foo' => 5), [], Factbase.new))
  end

  def test_assert_with_false_condition
    t = Factbase::Term.new(:assert, ['all must be positive', Factbase::Term.new(:gt, [:foo, 0])])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact('foo' => -1), [], Factbase.new)
      end
    assert_equal("all must be positive at (assert 'all must be positive' (gt foo 0))", e.message)
  end

  def test_assert_with_zero_value
    t = Factbase::Term.new(:assert, ['value must not be zero', Factbase::Term.new(:gt, [:foo, 0])])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact('foo' => 0), [], Factbase.new)
      end
    assert_equal("value must not be zero at (assert 'value must not be zero' (gt foo 0))", e.message)
  end

  def test_assert_with_array_true_condition
    t = Factbase::Term.new(:assert, ['at least one positive', Factbase::Term.new(:gt, [:foo, 0])])
    assert(t.evaluate(fact('foo' => [1, 2, 3]), [], Factbase.new))
  end

  def test_assert_with_array_false_condition
    t = Factbase::Term.new(:assert, ['at least one positive', Factbase::Term.new(:gt, [:foo, 0])])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact('foo' => [-1, -2, -3]), [], Factbase.new)
      end
    assert_equal("at least one positive at (assert 'at least one positive' (gt foo 0))", e.message)
  end

  def test_assert_with_mixed_array
    t = Factbase::Term.new(:assert, ['at least one positive', Factbase::Term.new(:gt, [:foo, 0])])
    assert(t.evaluate(fact('foo' => [-1, 0, 3]), [], Factbase.new))
  end

  def test_assert_raises_when_message_not_string
    e =
      assert_raises(StandardError) do
        Factbase::Term.new(:assert, [123, Factbase::Term.new(:gt, [:foo, 0])]).evaluate(fact, [], Factbase.new)
      end
    assert_match(/A string is expected as first argument of 'assert', but '123' provided/, e.message)
  end

  def test_assert_raises_when_second_arg_not_term
    e =
      assert_raises(StandardError) do
        Factbase::Term.new(:assert, %w[message not_a_term]).evaluate(fact, [], Factbase.new)
      end
    assert_match(/A term is expected as second argument of 'assert', but 'not_a_term' provided/, e.message)
  end

  def test_assert_raises_when_too_few_args
    e =
      assert_raises(StandardError) do
        Factbase::Term.new(:assert, ['message']).evaluate(fact, [], Factbase.new)
      end
    assert_match(/Too few \(\d+\) operands for 'assert' \(\d+ expected\)/, e.message)
  end

  def test_assert_raises_when_too_many_args
    e =
      assert_raises(StandardError) do
        Factbase::Term.new(:assert, ['message', Factbase::Term.new(:gt, [:foo, 0]), 'extra']).evaluate(fact, [],
                                                                                                       Factbase.new)
      end
    assert_match(/Too many \(\d+\) operands for 'assert' \(\d+ expected\)/, e.message)
  end
end
