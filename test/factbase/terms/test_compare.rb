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
      assert(Factbase::Term.new(:contains, [:tag, 'hello']).evaluate(f, [f], fb), f.to_s)
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
    assert_includes(e.message, "undefined method 'include?'")
  end
end
