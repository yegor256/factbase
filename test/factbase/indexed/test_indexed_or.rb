# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../../lib/factbase/indexed/indexed_or'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/term'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Indexed term 'or' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedOr < Factbase::Test
  def test_keeps_distinct_equal_facts_in_indexed_or
    maps = Array.new(2) { { 'name' => ['alice'], 'team' => ['blue'] } }
    10.times { maps << { 'name' => ['other'], 'team' => ['red'] } }
    plain = Factbase.new(maps)
    indexed = Factbase::IndexedFactbase.new(plain)
    query = '(or (eq name "alice") (eq team "blue"))'
    assert_equal(2, plain.query(query).each.count)
    assert_equal(2, indexed.query(query).each.count)
    assert_equal(%w[alice alice], indexed.query(query).each.map(&:name))
  end

  def test_deduplicates_overlapping_branches_by_fact_identity
    maps = [{ 'name' => ['alice'], 'team' => ['blue'] }]
    10.times { maps << { 'name' => ['other'], 'team' => ['red'] } }
    indexed = Factbase::IndexedFactbase.new(Factbase.new(maps))
    assert_equal(1, indexed.query('(or (eq name "alice") (eq team "blue"))').each.count)
    assert_equal(11, indexed.size)
  end

  def test_keeps_distinct_equal_facts_in_transactional_indexed_or
    maps = Array.new(2) { { 'name' => ['alice'], 'team' => ['blue'] } }
    10.times { maps << { 'name' => ['other'], 'team' => ['red'] } }
    indexed = Factbase::IndexedFactbase.new(Factbase.new(maps))
    query = '(or (eq name "alice") (eq team "blue"))'
    indexed.txn do |txn|
      assert_equal(2, txn.query(query).each.count)
      assert_equal(2, txn.query(query).each.count)
      txn.query(query).each { |fact| fact.visited = true }
      assert_equal(2, txn.query('(exists visited)').each.count)
    end
    assert_equal(2, indexed.query('(exists visited)').each.count)
  end

  def test_deduplicates_overlapping_branches_in_transactional_indexed_or
    maps = [{ 'name' => ['alice'], 'team' => ['blue'] }]
    10.times { maps << { 'name' => ['other'], 'team' => ['red'] } }
    indexed = Factbase::IndexedFactbase.new(Factbase.new(maps))
    query = '(or (eq name "alice") (eq team "blue"))'
    indexed.txn do |txn|
      assert_equal(1, txn.query(query).each.count)
      assert_equal(1, txn.query(query).each.count)
      txn.query(query).each { |fact| fact.visited = true }
      assert_equal(1, txn.query('(exists visited)').each.count)
    end
    assert_equal(1, indexed.query('(exists visited)').each.count)
  end

  def test_predicts_on_or
    term = Factbase::Term.new(
      :or,
      [
        Factbase::Term.new(:exists, [:bar]),
        Factbase::Term.new(:eq, [:foo, 42]),
        Factbase::Term.new(:eq, [:bar, 7])
      ]
    )
    term.redress!(Factbase::IndexedTerm, idx: {})
    n = term.predict(
      Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7], 'foo' => [22, 42] }, { 'foo' => [22, 42] }]), nil, {}
    )
    assert_equal(3, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_or_with_nil
    term = Factbase::Term.new(:or, [Factbase::Term.new(:boom, []), Factbase::Term.new(:exists, [:baz])])
    term.redress!(Factbase::IndexedTerm, idx: {})
    assert_nil(term.predict(Factbase::Taped.new([{ 'foo' => [1] }]), nil, {}))
  end

  def test_predicts_on_nested_or
    term = Factbase::Term.new(
      :or,
      [
        Factbase::Term.new(:or, [Factbase::Term.new(:eq, [:foo, 34])]),
        Factbase::Term.new(:or, [Factbase::Term.new(:boom, []), Factbase::Term.new(:eq, [:bar, 21])])
      ]
    )
    term.redress!(Factbase::IndexedTerm, idx: {})
    assert_equal(1, term.predict(Factbase::Taped.new([{ 'foo' => [34] }]), nil, {}).size)
  end
end
