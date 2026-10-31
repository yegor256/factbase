# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_and'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/term'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Indexed term 'and' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedAnd < Factbase::Test
  def test_predicts_on_and
    term = Factbase::Term.new(:and, [Factbase::Term.new(:eq, [:foo, 42]), Factbase::Term.new(:eq, %i[bar $jeff])])
    term.redress!(Factbase::IndexedTerm, idx: {})
    n = term.predict(
      Factbase::Taped.new(
        [
          { 'foo' => [42] }, { 'bar' => [7], 'foo' => [22, 42] },
          { 'foo' => [22, 42] }
        ]
      ), nil, Factbase::Tee.new({}, { 'jeff' => [7] })
    )
    assert_equal(1, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_single_and
    term = Factbase::Term.new(:and, [Factbase::Term.new(:eq, [:foo, 42])])
    term.redress!(Factbase::IndexedTerm, idx: {})
    assert_equal(
      1,
      term.predict(Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7], 'foo' => [4] }]), nil, {}).size
    )
  end

  def test_finds_facts_with_head_sorted_or_inverted_among_operands
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    200.times { fb.insert.a = 1 }
    [
      '(and (eq a 1) (inverted (always)))',
      '(and (eq a 1) (head 5 (always)))',
      '(and (exists a) (sorted a (always)))'
    ].each do |q|
      assert_equal(200, fb.query(q).each.to_a.size, q)
    end
  end

  def test_predicts_on_and_returns_nil
    term = Factbase::Term.new(
      :and,
      [
        Factbase::Term.new(:boom, []),
        Factbase::Term.new(:eq, [:foo, 42]),
        Factbase::Term.new(:eq, [:bar, 7])
      ]
    )
    term.redress!(Factbase::IndexedTerm, idx: {})
    assert_nil(term.predict(Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7] }]), nil, {}))
  end

  def test_multi_equality_matches_integer_fact_when_query_uses_equal_float
    origin = Factbase.new
    first = origin.insert
    first.amount = 1
    first.kind = 'selected'
    second = origin.insert
    second.amount = 2
    second.kind = 'selected'
    query = '(and (eq amount 1.0) (eq kind "selected"))'
    assert_equal(
      [1], origin.query(query).each.to_a.map(&:amount),
      'a plain factbase matches numerically equal Integer and Float values'
    )
    assert_equal(
      [1], Factbase::IndexedFactbase.new(origin).query(query).each.to_a.map(&:amount),
      'the multi-equality index must retain numerically equal Integer and Float values'
    )
  end

  def test_answers_like_the_plain_factbase_after_a_scoped_query
    query = '(and (eq z 7) (eq w 1))'
    plain = Factbase.new
    indexed = Factbase::IndexedFactbase.new(Factbase.new)
    [plain, indexed].each do |fb|
      4.times do |i|
        f = fb.insert
        f.z = 7
        f.w = i.even? ? 1 : 2
      end
      fb.insert.x = 0
    end
    indexed.query(query, indexed.to_enum(:each).to_a[2..]).each.to_a
    assert_equal(2, plain.query(query).each.to_a.size, 'the plain factbase must find both facts with z and w')
    assert_equal(
      plain.query(query).each.to_a.size,
      indexed.query(query).each.to_a.size,
      'the scoped query must not poison the multi-equality index of the next full query'
    )
  end

  def test_commits_writes_through_an_intersection_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    200.times do |i|
      f = fb.insert
      f.a = 1
      f.b = i
    end
    fb.txn { |fbt| fbt.query('(and (eq a 1) (exists b))').each { |f| f.c = 7 } }
    assert_equal(200, fb.query('(exists c)').each.to_a.size, 'writes through an intersection were lost on commit')
  end
end
