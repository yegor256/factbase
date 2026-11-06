# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/syntax'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/head'
require_relative '../../test__helper'

# Test for head term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestHead < Factbase::Test
  def test_takes_the_first_ones
    maps = [{ 'foo' => [1] }, { 'foo' => [2] }, { 'foo' => [3] }]
    assert_equal(
      2,
      Factbase::Term.new(:head, [2, Factbase::Term.new(:always, [])]).predict(maps, Factbase.new(maps), {}).size
    )
  end

  def test_stops_evaluating_after_finding_enough_facts
    fb = Factbase.new
    fb.insert.foo = 1
    fb.insert.foo = 'bad'
    assert_equal(1, fb.query('(head 1 (gt foo 0))').each.to_a.size)
  end

  def test_does_not_turn_a_param_into_a_property
    list = Factbase::Syntax.new('(head 1 (eq y $who))').to_term.predict(
      [{ 'y' => ['first'] }], Factbase.new, { 'who' => ['first'] }
    )
    list.each { |m| refute_includes(m.keys, 'who') }
  end

  def test_refuses_a_negative_count
    maps = [{ 'foo' => [1] }]
    t = Factbase::Term.new(:head, [-1, Factbase::Term.new(:always, [])])
    e = assert_raises(ArgumentError) { t.predict(maps, Factbase.new(maps), {}) }
    assert_includes(e.message, "A non-negative count is expected by 'head', but -1 provided", e.message)
  end

  def test_takes_all_facts_for_a_huge_count
    fb = Factbase.new
    fb.insert.x = 1
    fb.insert.x = 2
    assert_equal(2, fb.query('(head 99999999999999999999 (always))').each.to_a.size)
  end

  def test_takes_as_many_as_a_param_says
    fb = Factbase.new
    [5, 7, 9].each { |i| fb.insert.v = i }
    assert_equal(2, fb.query('(head $n (always))').each(fb, 'n' => [2]).to_a.size)
    assert_equal(2, fb.query('(agg (head $n (always)) (count))').one(fb, 'n' => [2]))
  end

  def test_takes_as_many_as_a_sub_term_says
    fb = Factbase.new
    [5, 7, 9].each { |i| fb.insert.v = i }
    assert_equal(2, fb.query('(head (plus 1 1) (always))').each.to_a.size)
  end

  def test_refuses_a_count_of_several_values
    fb = Factbase.new
    fb.insert.v = 1
    e = assert_raises(StandardError) { fb.query('(head $n (always))').each(fb, 'n' => [1, 2]).to_a }
    assert_includes(e.message, "An integer is expected as first argument of 'head'", e.message)
  end
end
