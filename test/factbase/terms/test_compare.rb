# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/compare'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for the 'compare' term.
class TestCompare < Factbase::Test
  def test_does_not_depend_on_the_order_of_the_values
    fb = Factbase.new
    first = fb.insert
    first.tag = 'hello world'
    first.tag = 42
    second = fb.insert
    second.tag = 42
    second.tag = 'hello world'
    [first, second].each do |f|
      assert(Factbase::Term.new(:contains, [:tag, 'hello']).evaluate(f, [f], fb))
    end
  end

  def test_raises_when_no_pairing_is_comparable
    fb = Factbase.new
    f = fb.insert
    f.tag = 42
    assert_raises(StandardError) do
      Factbase::Term.new(:contains, [:tag, 'hello']).evaluate(f, [f], fb)
    end
  end

  def test_evaluates_comparison
    assert(Factbase::Compare.new(:>, [4, 2]).evaluate(fact, [], Factbase.new), 'Expected 4 > 2 to be true')
  end

  def test_evaluates_comparison_less
    refute(Factbase::Compare.new(:<, [4, 2]).evaluate(fact, [], Factbase.new), 'Expected 2 < 4 to be true')
  end

  def test_rounds_time_the_same_way_for_every_operator
    t = Time.utc(2024, 1, 1, 0, 0, 0, 500_000)
    whole = Time.utc(2024, 1, 1)
    assert(Factbase::Compare.new(:==, [t, whole]).evaluate(fact, [], Factbase.new))
    assert(Factbase::Compare.new(:<=, [t, whole]).evaluate(fact, [], Factbase.new))
    assert(Factbase::Compare.new(:>=, [t, whole]).evaluate(fact, [], Factbase.new))
    refute(Factbase::Compare.new(:<, [t, whole]).evaluate(fact, [], Factbase.new))
    refute(Factbase::Compare.new(:>, [t, whole]).evaluate(fact, [], Factbase.new))
  end

  def test_wraps_incompatible_type_comparison
    t = Factbase::Compare.new(:>, [42, 'hello'])
    e = assert_raises(RuntimeError) { t.evaluate(fact, [], Factbase.new) }
    assert_includes(e.message, 'Cannot compare 42 (Integer) with "hello" (String)')
    assert_includes(e.message, 'using (compare >)')
    assert_includes(e.message, 'comparison of Integer with String failed')
  end

  def test_wraps_incompatible_time_comparison
    t = Factbase::Compare.new(:<, [Time.utc(2024, 1, 1), 'yesterday'])
    e = assert_raises(RuntimeError) { t.evaluate(fact, [], Factbase.new) }
    assert_includes(e.message, 'Time')
    assert_includes(e.message, '"yesterday" (String)')
    assert_includes(e.message, 'comparison of Time with String failed')
  end

  def test_wraps_a_missing_comparison_method
    t = Factbase::Compare.new(:include?, [42, 7])
    e = assert_raises(RuntimeError) { t.evaluate(fact, [], Factbase.new) }
    assert_includes(e.message, 'Cannot compare 42 (Integer) with 7 (Integer)')
    assert_includes(e.message, 'using (compare include?)')
    assert_match(/undefined method [`']include\?'/, e.message)
  end

  def test_keeps_looking_past_incomparable_pairing_on_right_side
    fb = Factbase.new
    f = fb.insert
    f.tag = 'hello'
    f.pat = 1
    f.pat = 'ell'
    assert_equal(1, fb.query('(contains tag pat)').each.to_a.size)
    assert(Factbase::Term.new(:contains, %i[tag pat]).evaluate(f, [f], fb))
    assert(Factbase::Compare.new(:include?, %i[tag pat]).evaluate(f, [f], fb))
  end

  def test_answers_false_when_comparable_pairing_does_not_match_with_mixed_values
    fb = Factbase.new
    g = fb.insert
    g.tag = 42
    g.tag = 'hi'
    assert_equal(0, fb.query("(contains tag 'hello')").each.to_a.size)
    refute(Factbase::Term.new(:contains, [:tag, 'hello']).evaluate(g, [g], fb))
    refute(Factbase::Compare.new(:include?, [:tag, 'hello']).evaluate(g, [g], fb))
  end

  def test_answers_false_when_right_operand_has_mixed_incomparable_and_unmatched_values
    fb = Factbase.new
    f = fb.insert
    f.tag = 'hello'
    f.pat = 42
    f.pat = 'world'
    assert_equal(0, fb.query('(contains tag pat)').each.to_a.size)
    refute(Factbase::Term.new(:contains, %i[tag pat]).evaluate(f, [f], fb))
    refute(Factbase::Compare.new(:include?, %i[tag pat]).evaluate(f, [f], fb))
  end

  def test_keeps_looking_past_incomparable_right_pairing_for_greater_than
    fb = Factbase.new
    f = fb.insert
    f.num = 10
    f.bound = 'bad'
    f.bound = 5
    assert_equal(1, fb.query('(gt num bound)').each.to_a.size)
    assert(Factbase::Compare.new(:>, %i[num bound]).evaluate(f, [f], fb))
  end

  def test_answers_false_when_greater_than_has_mixed_incomparable_values_and_no_match
    fb = Factbase.new
    f = fb.insert
    f.num = 'bad'
    f.num = 2
    assert_equal(0, fb.query('(gt num 5)').each.to_a.size)
    refute(Factbase::Compare.new(:>, [:num, 5]).evaluate(f, [f], fb))
  end
end
