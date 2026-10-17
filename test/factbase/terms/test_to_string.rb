# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'time'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_string'
require_relative '../../test__helper'

# Test for 'to_string' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToString < Factbase::Test
  def test_to_str
    assert_equal('String', Factbase::ToString.new([Time.now]).evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_string_returns_exact_text_not_inspect
    assert_equal('abc', Factbase::ToString.new(['abc']).evaluate(fact, [], Factbase.new))
    assert_equal('hello world', Factbase::ToString.new([:s]).evaluate(fact('s' => 'hello world'), [], Factbase.new))
  end

  def test_integer_returns_exact_string
    assert_equal('42', Factbase::ToString.new([42]).evaluate(fact, [], Factbase.new))
    assert_equal('-7', Factbase::ToString.new([:n]).evaluate(fact('n' => -7), [], Factbase.new))
  end

  def test_float_returns_exact_string
    assert_equal('3.14', Factbase::ToString.new([3.14]).evaluate(fact, [], Factbase.new))
    assert_equal('-0.5', Factbase::ToString.new([:f]).evaluate(fact('f' => -0.5), [], Factbase.new))
  end

  def test_time_returns_exact_string
    now = Time.utc(2024, 1, 1, 10, 0, 0)
    assert_equal(now.to_s, Factbase::ToString.new([now]).evaluate(fact, [], Factbase.new))
    assert_equal(now.to_s, Factbase::ToString.new([:t]).evaluate(fact('t' => now), [], Factbase.new))
  end

  def test_array_returns_first_element_as_string
    assert_equal('first', Factbase::ToString.new([%w[first second]]).evaluate(fact, [], Factbase.new))
    assert_equal('42', Factbase::ToString.new([[42, 99]]).evaluate(fact, [], Factbase.new))
    assert_equal('foo', Factbase::ToString.new([:arr]).evaluate(fact('arr' => %w[foo bar]), [], Factbase.new))
  end

  def test_returns_nil_for_absent_property
    assert_nil(Factbase::ToString.new([:missing]).evaluate(fact, [], Factbase.new))
  end

  def test_query_execution_with_string
    fb = Factbase.new
    fb.insert.s = 'abc'
    assert_equal(1, fb.query('(eq (to_string s) "abc")').each.to_a.size)
  end

  def test_query_execution_with_integer_and_float
    fb = Factbase.new
    f = fb.insert
    f.num = 42
    f.flt = 3.14
    assert_equal(1, fb.query('(eq (to_string num) "42")').each.to_a.size)
    assert_equal(1, fb.query('(eq (to_string flt) "3.14")').each.to_a.size)
  end

  def test_query_execution_with_time
    fb = Factbase.new
    now = Time.utc(2024, 1, 1, 10, 0, 0)
    fb.insert.t = now
    assert_equal(1, fb.query("(eq (to_string t) \"#{now}\")").each.to_a.size)
  end

  def test_query_execution_with_array
    fb = Factbase.new
    f = fb.insert
    f.tags = 'first'
    f.tags = 'second'
    assert_equal(1, fb.query('(eq (to_string tags) "first")').each.to_a.size)
  end

  def test_asserts_arguments_count
    assert_raises(ArgumentError) { Factbase::ToString.new([]).evaluate(fact, [], Factbase.new) }
    assert_raises(ArgumentError) { Factbase::ToString.new(%w[a b]).evaluate(fact, [], Factbase.new) }
  end
end
