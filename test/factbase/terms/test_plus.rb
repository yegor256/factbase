# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/plus'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'plus' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestPlus < Factbase::Test
  def test_plus
    t = Factbase::Plus.new([:foo, 42])
    assert_equal(46, t.evaluate(fact('foo' => 4), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_plus_time
    t = Factbase::Plus.new([:foo, '12 days'])
    assert_equal(Time.parse('2024-01-13'), t.evaluate(fact('foo' => Time.parse('2024-01-01')), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_plus_time_seconds
    time = Time.utc(2000, 1, 1, 0, 0, 21)
    t = Factbase::Plus.new([:foo, '21 seconds'])
    assert_equal(time + 21, t.evaluate(fact('foo' => time), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_plus_time_minutesseconds
    time = Time.utc(2000, 1, 1, 0, 21, 0)
    t = Factbase::Plus.new([:foo, '21 minutes'])
    assert_equal(time + (21 * 60), t.evaluate(fact('foo' => time), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_plus_time_hoursminutes
    time = Time.utc(2000, 1, 1, 21, 0, 0)
    t = Factbase::Plus.new([:foo, '21 hours'])
    assert_equal(time + (21 * 60 * 60), t.evaluate(fact('foo' => time), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_plus_time_weeks
    time = Time.utc(2000, 1, 1, 0, 0, 0)
    t = Factbase::Plus.new([:foo, '3 weeks'])
    assert_equal(time + (3 * 60 * 60 * 24 * 7), t.evaluate(fact('foo' => time), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_rejects_underscores_in_a_duration_of_plus
    fb = Factbase.new
    f = fb.insert
    f.start = Time.utc(2024, 1, 1)
    f.span = '1_0 days'
    assert_includes(
      assert_raises(StandardError) { fb.query('(as later (plus start span))').each.to_a }.message,
      "Amount '1_0' in '1_0 days' must be a whole number"
    )
  end

  def test_rejects_a_string_as_the_first_operand
    assert_includes(
      assert_raises(ArgumentError) do
        Factbase::Plus.new(%i[foo bar]).evaluate(fact('foo' => 'x', 'bar' => 'y'), [], Factbase.new)
      end.message,
      'Cannot apply + to x (String)'
    )
  end

  def test_rejects_a_string_as_the_second_operand
    assert_includes(
      assert_raises(ArgumentError) do
        Factbase::Plus.new(%i[foo bar]).evaluate(fact('foo' => 3, 'bar' => 'x'), [], Factbase.new)
      end.message,
      'Cannot apply + to 3 (Integer) and x (String)'
    )
  end

  def test_does_not_concatenate_two_strings
    fb = Factbase.new
    f = fb.insert
    f.b = 'x'
    f.c = 'y'
    assert_includes(
      assert_raises(StandardError) { fb.query('(as z (plus b c))').each.to_a }.message,
      'Cannot apply + to x (String)'
    )
  end

  def test_does_not_repeat_the_same_string
    fb = Factbase.new
    fb.insert.b = 'x'
    assert_includes(
      assert_raises(StandardError) { fb.query('(as z (plus b b))').each.to_a }.message,
      'Cannot apply + to x (String)'
    )
  end

  def test_explains_a_string_on_the_right_of_plus
    fb = Factbase.new
    f = fb.insert
    f.a = 3
    f.b = 'x'
    assert_includes(
      assert_raises(StandardError) { fb.query('(eq a (plus a b))').each.to_a }.message,
      'Cannot apply + to 3 (Integer) and x (String)'
    )
  end

  def test_explains_a_string_on_the_left_of_plus
    fb = Factbase.new
    f = fb.insert
    f.a = 3
    f.b = 'x'
    assert_includes(
      assert_raises(StandardError) { fb.query('(eq a (plus b a))').each.to_a }.message,
      'Cannot apply + to x (String)'
    )
  end
end
