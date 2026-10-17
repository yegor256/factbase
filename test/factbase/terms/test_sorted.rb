# frozen_string_literal: true

require_relative '../../../lib/factbase/syntax'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/sorted'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for sorted term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSorted < Factbase::Test
  def test_sorting
    list = Factbase::Syntax.new('(sorted x (always))').to_term.predict(
      [
        { 'x' => [8], 'y' => ['third'] }, { 'x' => [1], 'y' => ['first'] },
        { 'x' => [4], 'y' => ['second'] }
      ], Factbase.new, {}
    )
    assert(list.all?(Hash), "Why not all hashes in the list: #{list}")
    assert_equal('first second third', list.map { |m| m['y'].first }.join(' '))
  end

  def test_keeps_facts_without_the_property
    list = Factbase::Syntax.new('(sorted x (always))').to_term.predict(
      [
        { 'x' => [8], 'y' => ['third'] }, { 'y' => ['nothing'] },
        { 'x' => [1], 'y' => ['first'] }
      ], Factbase.new, {}
    )
    assert_equal('first third nothing', list.map { |m| m['y'].first }.join(' '))
  end

  def test_keeps_insertion_order_of_equal_values
    list = Factbase::Syntax.new('(sorted k (always))').to_term.predict(
      Array.new(17) { |i| { 'id' => [i], 'k' => [i % 2] } }, Factbase.new, {}
    )
    assert_equal([*0.step(16, 2), *1.step(15, 2)], list.map { |m| m['id'].first })
  end

  def test_sorts_values_of_different_types
    list = Factbase::Syntax.new('(sorted score (always))').to_term.predict(
      [{ 'score' => ['two'] }, { 'score' => [1] }], Factbase.new, {}
    )
    assert_equal([1, 'two'], list.map { |m| m['score'].first })
  end

  def test_does_not_turn_a_param_into_a_property
    list = Factbase::Syntax.new('(sorted x (eq y $who))').to_term.predict(
      [{ 'x' => [8], 'y' => ['first'] }, { 'x' => [1], 'y' => ['second'] }],
      Factbase.new, { 'who' => %w[first second] }
    )
    list.each { |m| refute_includes(m.keys, 'who') }
  end

  def test_join_and_sort
    ff = Factbase.new(
      [
        { 'foo' => [888] }, { 'foo' => [111] },
        { 'foo' => [444] }
      ]
    ).query('(join "f<=foo" (head 1 (sorted foo (eq foo $foo))))').each.to_a
    assert_equal('888 111 444', ff.map { |m| m['f'].first }.join(' '))
  end

  def test_orders_facts_by_first_value_with_integers
    fb = Factbase.new
    f = fb.insert
    f.id = 'f'
    f.k = 9
    f.k = 1
    g = fb.insert
    g.id = 'g'
    g.k = 5
    h = fb.insert
    h.id = 'h'
    h.k = 2
    h.k = 10
    sorted = fb.query('(sorted k (always))').each.to_a
    assert_equal(%w[h g f], sorted.map { |m| m['id'].first })
  end

  def test_orders_facts_by_first_value_with_strings
    fb = Factbase.new
    f = fb.insert
    f.id = 'f'
    f.tag = 'zebra'
    f.tag = 'apple'
    g = fb.insert
    g.id = 'g'
    g.tag = 'mango'
    h = fb.insert
    h.id = 'h'
    h.tag = 'banana'
    h.tag = 'zoo'
    sorted = fb.query('(sorted tag (always))').each.to_a
    assert_equal(%w[h g f], sorted.map { |m| m['id'].first })
  end

  def test_orders_facts_by_first_value_with_times
    fb = Factbase.new
    early = Time.utc(2025, 1, 1)
    late = Time.utc(2025, 12, 1)
    f = fb.insert
    f.id = 'f'
    f.when = late
    f.when = early
    g = fb.insert
    g.id = 'g'
    g.when = Time.utc(2025, 6, 1)
    h = fb.insert
    h.id = 'h'
    h.when = early
    h.when = late
    sorted = fb.query('(sorted when (always))').each.to_a
    assert_equal(%w[h g f], sorted.map { |m| m['id'].first })
  end

  def test_predict_orders_facts_by_first_value
    list = Factbase::Syntax.new('(sorted k (always))').to_term.predict(
      [
        { 'id' => ['f'], 'k' => [99, 1] },
        { 'id' => ['g'], 'k' => [50] },
        { 'id' => ['h'], 'k' => [10, 100] }
      ], Factbase.new, {}
    )
    assert_equal(%w[h g f], list.map { |m| m['id'].first })
  end

  def test_orders_facts_with_differing_value_counts
    fb = Factbase.new
    f = fb.insert
    f.id = 'f'
    f.k = 30
    f.k = 1
    f.k = 5
    g = fb.insert
    g.id = 'g'
    g.k = 20
    h = fb.insert
    h.id = 'h'
    h.k = 10
    h.k = 100
    sorted = fb.query('(sorted k (always))').each.to_a
    assert_equal(%w[h g f], sorted.map { |m| m['id'].first })
  end
end
