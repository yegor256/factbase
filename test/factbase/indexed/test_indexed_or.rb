# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_or'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/term'

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

  # 9 + 9 candidates exceed the 16-element Array#| threshold that starts hashing.
  def test_does_not_hash_facts_while_merging
    maps = Array.new(200) { |i| { 'uniq' => [i] } }
    (0..8).each { |i| maps[i]['foo'] = [1] }
    (9..17).each { |i| maps[i]['bar'] = [2] }
    maps.each do |m|
      m.define_singleton_method(:hash) { raise(RuntimeError, 'fact must not be hashed') }
    end
    term = Factbase::Term.new(:or, [Factbase::Term.new(:eq, [:foo, 1]), Factbase::Term.new(:eq, [:bar, 2])])
    term.redress!(Factbase::IndexedTerm, idx: {})
    assert_equal(18, term.predict(maps, nil, {}).size)
  end

  def test_merges_equal_but_distinct_facts
    maps = Array.new(16) { |i| { 'foo' => [i] } }
    maps[3] = { 'foo' => [42], 'bar' => [7] }
    maps[4] = { 'foo' => [42] }
    maps[5] = { 'foo' => [42] }
    maps[6] = { 'bar' => [7] }
    term = Factbase::Term.new(:or, [Factbase::Term.new(:eq, [:foo, 42]), Factbase::Term.new(:eq, [:bar, 7])])
    term.redress!(Factbase::IndexedTerm, idx: {})
    n = term.predict(maps, nil, {})
    assert_equal(4, n.size)
    assert(n.any? { |f| f.equal?(maps[4]) })
    assert(n.any? { |f| f.equal?(maps[5]) })
    assert_equal(1, n.count { |f| f.equal?(maps[3]) })
  end

  # 4 maps keep 1 match under the maps.size / 4 threshold, so the loop reaches the repack return.
  def test_repacks_the_merged_result
    term = Factbase::Term.new(:or, [Factbase::Term.new(:eq, [:foo, 1]), Factbase::Term.new(:eq, [:bar, 2])])
    term.redress!(Factbase::IndexedTerm, idx: {})
    n = term.predict(
      Factbase::Taped.new(
        [{ 'foo' => [1], 'bar' => [2] }, { 'foo' => [3] }, { 'foo' => [4] }, { 'foo' => [5] }], inserted: [11]
      ),
      nil,
      {}
    )
    assert_kind_of(Factbase::Taped, n)
    assert_equal(1, n.size)
    assert_equal([11], n.inserted)
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
