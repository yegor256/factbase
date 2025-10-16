# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/assert'

# Test for assert term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestAssert < Factbase::Test
  def test_assert_with_true_condition
    t = Factbase::Assert.new(['all must be positive', Factbase::Term.new(:gt, [:foo, 0])])
    assert(t.evaluate(fact('foo' => 5), [], Factbase.new))
  end

  def test_assert_with_false_condition
    t = Factbase::Assert.new(['all must be positive', Factbase::Term.new(:gt, [:foo, 0])])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact('foo' => -1), [], Factbase.new)
      end
    assert_includes(e.message, 'all must be positive')
  end

  def test_assert_with_zero_value
    t = Factbase::Assert.new(['value must not be zero', Factbase::Term.new(:gt, [:foo, 0])])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact('foo' => 0), [], Factbase.new)
      end
    assert_includes(e.message, 'value must not be zero')
  end

  def test_assert_with_array_true_condition
    t = Factbase::Assert.new(['at least one positive', Factbase::Term.new(:gt, [:foo, 0])])
    assert(t.evaluate(fact('foo' => [1, 2, 3]), [], Factbase.new))
  end

  def test_assert_with_array_false_condition
    t = Factbase::Assert.new(['at least one positive', Factbase::Term.new(:gt, [:foo, 0])])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact('foo' => [-1, -2, -3]), [], Factbase.new)
      end
    assert_includes(e.message, 'at least one positive')
  end

  def test_assert_with_mixed_array
    t = Factbase::Assert.new(['at least one positive', Factbase::Term.new(:gt, [:foo, 0])])
    assert(t.evaluate(fact('foo' => [-1, 0, 3]), [], Factbase.new))
  end

  def test_assert_raises_when_message_not_string
    e =
      assert_raises(StandardError) do
        Factbase::Assert.new([123, Factbase::Term.new(:gt, [:foo, 0])]).evaluate(fact, [], Factbase.new)
      end
    assert_match(/A string is expected as first argument of 'assert', but '123' provided/, e.message)
  end

  def test_assert_raises_when_second_arg_not_term
    e =
      assert_raises(StandardError) do
        Factbase::Assert.new(%w[message not_a_term]).evaluate(fact, [], Factbase.new)
      end
    assert_match(/A term is expected as second argument of 'assert', but 'not_a_term' provided/, e.message)
  end

  def test_assert_raises_when_too_few_args
    e =
      assert_raises(StandardError) do
        Factbase::Assert.new(['message']).evaluate(fact, [], Factbase.new)
      end
    assert_match(/Too few \(\d+\) operands for 'assert' \(\d+ expected\)/, e.message)
  end

  def test_assert_raises_when_too_many_args
    e =
      assert_raises(StandardError) do
        Factbase::Assert.new(['message', Factbase::Term.new(:gt, [:foo, 0]), 'extra']).evaluate(fact, [], Factbase.new)
      end
    assert_match(/Too many \(\d+\) operands for 'assert' \(\d+ expected\)/, e.message)
  end
end
