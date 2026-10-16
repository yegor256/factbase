# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_eq'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/lazy_taped'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/term'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Indexed term 'eq' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedEq < Factbase::Test
  def test_predicts_on_eq_with_array
    [
      { input: [{ 'foo' => [42] }, { 'bar' => [1] }], expected: 1 },
      { input: [{ 'foo' => [42] }, { 'foo' => [42] }, { 'foo' => [1, 42] }], expected: 3 }
    ].each do |c|
      term = Factbase::Term.new(:eq, [:foo, 42])
      term.redress!(Factbase::IndexedTerm, idx: {})
      assert_equal(c[:expected], term.predict(c[:input], nil, {}).size, "Failed on Array for #{c[:input]}")
    end
  end

  def test_predicts_on_eq_with_taped
    [
      { input: [{ 'foo' => [42] }, { 'bar' => [1] }], expected: 1 },
      { input: [{ 'foo' => [42] }, { 'foo' => [42] }, { 'foo' => [1, 42] }], expected: 3 }
    ].each do |c|
      term = Factbase::Term.new(:eq, [:foo, 42])
      term.redress!(Factbase::IndexedTerm, idx: {})
      assert_equal(
        c[:expected], term.predict(Factbase::Taped.new(c[:input]), nil, {}).size,
        "Failed on Taped for #{c[:input]}"
      )
    end
  end

  def test_predicts_on_eq_with_lazy_taped
    [
      { input: [{ 'foo' => [42] }, { 'bar' => [1] }], expected: 1 },
      { input: [{ 'foo' => [42] }, { 'foo' => [42] }, { 'foo' => [1, 42] }], expected: 3 }
    ].each do |c|
      term = Factbase::Term.new(:eq, [:foo, 42])
      term.redress!(Factbase::IndexedTerm, idx: {})
      assert_equal(
        c[:expected], term.predict(Factbase::LazyTaped.new(c[:input]), nil, {}).size,
        "Failed on LazyTaped for #{c[:input]}"
      )
    end
  end

  def test_predict_decorator_persistence
    [
      { input: [{ 'foo' => [42] }], expected: Array },
      { input: Factbase::Taped.new([{ 'foo' => [42] }]), expected: Factbase::Taped },
      { input: Factbase::LazyTaped.new([{ 'foo' => [42] }]), expected: Factbase::Taped }
    ].each do |c|
      term = Factbase::Term.new(:eq, [:foo, 42])
      term.redress!(Factbase::IndexedTerm, idx: {})
      n = term.predict(c[:input], nil, {})
      assert_kind_of(c[:expected], n, "Expect #{c[:expected]}, but got #{n.class} for input #{c[:input].class}")
    end
  end

  def test_yields_a_fact_with_repeated_values_once
    maps = [{ 'a' => [2, 2] }, { 'a' => [1] }]
    assert_equal(
      Factbase.new(maps.map(&:dup)).query('(eq a 2)').each.to_a.size,
      Factbase::IndexedFactbase.new(Factbase.new(maps.map(&:dup))).query('(eq a 2)').each.to_a.size,
      'a fact that stores the same value twice must be returned once, as it is without the index'
    )
  end

  def test_matches_integer_fact_when_query_uses_equal_float
    origin = Factbase.new
    origin.insert.amount = 1
    query = '(eq amount 1.0)'
    assert_equal([1], origin.query(query).each.to_a.map(&:amount))
    assert_equal([1], Factbase::IndexedFactbase.new(origin).query(query).each.to_a.map(&:amount))
  end

  def test_keeps_the_order_of_facts_for_a_multi_valued_parameter
    plain = Factbase.new
    indexed = Factbase::IndexedFactbase.new(Factbase.new)
    [plain, indexed].each do |fb|
      fb.insert.rank = 2
      fb.insert.rank = 1
    end
    params = { 'ranks' => [1, 2] }
    assert_equal(
      plain.query('(eq rank $ranks)').each(plain, params).map(&:rank),
      indexed.query('(eq rank $ranks)').each(indexed, params).map(&:rank)
    )
  end

  def test_matches_scalar_false_query_parameter
    term = Factbase::Term.new(:eq, %i[enabled $enabled])
    term.redress!(Factbase::IndexedTerm, idx: {})
    maps = [{ 'enabled' => [false], 'tag' => ['off'] }, { 'enabled' => [true], 'tag' => ['on'] }]
    assert_equal(['off'], term.predict(maps, nil, { '$enabled' => false }).to_a.map { |m| m['tag'].first })
    assert_equal(['off'], term.predict(maps, nil, { 'enabled' => false }).to_a.map { |m| m['tag'].first })
    assert_equal(['on'], term.predict(maps, nil, { '$enabled' => true }).to_a.map { |m| m['tag'].first })
    assert_equal(['off'], term.predict(maps, nil, { '$enabled' => [false] }).to_a.map { |m| m['tag'].first })
  end

  def test_matches_literal_boolean_values
    term = Factbase::Term.new(:eq, [:enabled, false])
    term.redress!(Factbase::IndexedTerm, idx: {})
    maps = [{ 'enabled' => [false], 'name' => ['a'] }, { 'enabled' => [true], 'name' => ['b'] }]
    assert_equal(['a'], term.predict(maps, nil, {}).to_a.map { |m| m['name'].first })
  end

  def test_compares_plain_and_indexed_on_boolean_values
    plain = Factbase.new
    indexed = Factbase::IndexedFactbase.new(Factbase.new)
    [plain, indexed].each do |fb|
      first = fb.insert
      first.enabled = false
      first.tag = 'inactive'
      second = fb.insert
      second.enabled = true
      second.tag = 'active'
    end
    [
      ['(eq enabled $enabled)', { 'enabled' => false }, ['inactive']],
      ['(eq enabled $enabled)', { 'enabled' => true }, ['active']],
      ['(eq enabled false)', {}, ['inactive']],
      ['(eq enabled true)', {}, ['active']]
    ].each do |query, params, expected|
      assert_equal(expected, plain.query(query).each(plain, params).map(&:tag))
      assert_equal(expected, indexed.query(query).each(indexed, params).map(&:tag))
    end
  end
end
