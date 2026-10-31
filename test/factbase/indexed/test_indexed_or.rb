# frozen_string_literal: true

require_relative '../../../lib/factbase'
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
