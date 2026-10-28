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

  def test_dont_predict_when_an_operand_is_head
    term = Factbase::Term.new(
      :or,
      [
        Factbase::Term.new(:head, [1, Factbase::Term.new(:eq, [:x, 3])]),
        Factbase::Term.new(:eq, [:x, 5])
      ]
    )
    term.redress!(Factbase::IndexedTerm, idx: {})
    assert_nil(
      term.predict(Factbase::Taped.new(Array.new(20) { |i| { 'x' => [i] } }), Factbase.new, {}),
      'or predicted the copies that head made'
    )
  end

  def test_finds_the_same_facts_as_plain_factbase_with_sorted_inside
    plain = Factbase.new
    indexed = Factbase::IndexedFactbase.new(Factbase.new)
    [plain, indexed].each { |fb| 20.times { |i| fb.insert.x = i } }
    q = '(or (sorted x (eq x 3)) (eq x 5))'
    assert_equal(
      plain.query(q).each.map(&:x), indexed.query(q).each.map(&:x),
      'or with sorted inside finds other facts than plain factbase'
    )
  end

  def test_keeps_writes_through_or_with_inverted_inside
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    20.times { |i| fb.insert.x = i }
    fb.query('(or (inverted (eq x 3)) (eq x 5))').each { |f| f.y = 1 }
    assert_equal(20, fb.query('(exists y)').each.to_a.size, 'writes through or with inverted inside are lost')
  end
end
