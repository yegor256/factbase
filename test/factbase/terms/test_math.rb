# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'

# Math test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestMath < Factbase::Test
  def test_simple
    t = Factbase::Term.new(:eq, [:foo, 42])
    assert(t.evaluate(fact('foo' => [42]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 'Hello!'), [], Factbase.new))
    refute(t.evaluate(fact('bar' => ['Hello!']), [], Factbase.new))
  end

  def test_zero
    t = Factbase::Term.new(:zero, [:foo])
    assert(t.evaluate(fact('foo' => [0]), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [10, 5, 6, -8, 'hey', 0, 9, 'fdsf']), [], Factbase.new))
    refute(t.evaluate(fact('foo' => [100]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => []), [], Factbase.new))
    refute(t.evaluate(fact('bar' => []), [], Factbase.new))
  end

  def test_eq
    t = Factbase::Term.new(:eq, [:foo, 42])
    assert(t.evaluate(fact('foo' => 42), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [10, 5, 6, -8, 'hey', 42, 9, 'fdsf']), [], Factbase.new))
    refute(t.evaluate(fact('foo' => [100]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => []), [], Factbase.new))
    refute(t.evaluate(fact('bar' => []), [], Factbase.new))
  end

  def test_eq_time
    now = Time.now
    t = Factbase::Term.new(:eq, [:foo, Time.parse(now.iso8601)])
    assert(t.evaluate(fact('foo' => now), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [now, Time.now]), [], Factbase.new))
  end

  def test_lt
    t = Factbase::Term.new(:lt, [:foo, 42])
    assert(t.evaluate(fact('foo' => [10]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => [100]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 100), [], Factbase.new))
    refute(t.evaluate(fact('bar' => 100), [], Factbase.new))
  end

  def test_gte
    t = Factbase::Term.new(:gte, [:foo, 42])
    assert(t.evaluate(fact('foo' => 100), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 42), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 41), [], Factbase.new))
  end

  def test_lte
    t = Factbase::Term.new(:lte, [:foo, 42])
    assert(t.evaluate(fact('foo' => 41), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 42), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 100), [], Factbase.new))
  end

  def test_gt
    t = Factbase::Term.new(:gt, [:foo, 42])
    assert(t.evaluate(fact('foo' => [100]), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 100), [], Factbase.new))
    refute(t.evaluate(fact('foo' => [10]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 10), [], Factbase.new))
    refute(t.evaluate(fact('bar' => 10), [], Factbase.new))
  end

  def test_lt_time
    t = Factbase::Term.new(:lt, [:foo, Time.now])
    assert(t.evaluate(fact('foo' => [Time.now - 100]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => [Time.now + 100]), [], Factbase.new))
    refute(t.evaluate(fact('bar' => [100]), [], Factbase.new))
  end

  def test_gt_time
    t = Factbase::Term.new(:gt, [:foo, Time.now])
    assert(t.evaluate(fact('foo' => [Time.now + 100]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => [Time.now - 100]), [], Factbase.new))
    refute(t.evaluate(fact('bar' => [100]), [], Factbase.new))
  end

  def test_plus
    t = Factbase::Term.new(:plus, [:foo, 42])
    assert_equal(46, t.evaluate(fact('foo' => 4), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_plus_time
    t = Factbase::Term.new(:plus, [:foo, '12 days'])
    assert_equal(Time.parse('2024-01-13'), t.evaluate(fact('foo' => Time.parse('2024-01-01')), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_minus
    t = Factbase::Term.new(:minus, [:foo, 42])
    assert_equal(58, t.evaluate(fact('foo' => 100), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_minus_time
    t = Factbase::Term.new(:minus, [:foo, '4 hours'])
    assert_equal(Time.parse('2024-01-01T06:04'),
                 t.evaluate(fact('foo' => Time.parse('2024-01-01T10:04')), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_minus_time_singular
    t = Factbase::Term.new(:minus, [:foo, '1 hour'])
    assert_equal(Time.parse('2024-01-01T09:04'),
                 t.evaluate(fact('foo' => Time.parse('2024-01-01T10:04')), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end
end
