# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/lazy_taped'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/indexed/indexed_unique'

# Indexed term 'unique' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedUnique < Factbase::Test
  def test_predicts_on_unique
    term = Factbase::Term.new(:unique, [:foo])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new(
      [
        { 'foo' => [42] },
        { 'foo' => [42] },
        { 'foo' => [7] },
        { 'bar' => [100] }
      ]
    )
    n = term.predict(maps, nil, {})
    assert_equal(2, n.size)
    assert_equal([{ 'foo' => [42] }, { 'foo' => [7] }], n.to_a)
  end

  def test_predicts_on_unique_with_combinations
    term = Factbase::Term.new(:unique, %i[foo bar])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new(
      [
        { 'foo' => [42], 'bar' => ['a'] },
        { 'foo' => [7], 'baz' => ['a'] },
        { 'foo' => [42], 'bar' => ['b'] },
        { 'foo' => [52] }
      ]
    )
    n = term.predict(maps, nil, {})
    assert_equal(2, n.size)
    assert_equal([{ 'foo' => [42], 'bar' => ['a'] }, { 'foo' => [42], 'bar' => ['b'] }], n.to_a)
  end

  def test_collision_with_array
    _assert_collision { |input| input }
  end

  def test_collision_with_taped
    _assert_collision { |input| Factbase::Taped.new(input) }
  end

  def test_collision_with_lazy_taped
    _assert_collision { |input| Factbase::LazyTaped.new(input) }
  end

  def test_context_with_array
    _assert_context { |input| input }
  end

  def test_context_with_taped
    _assert_context { |input| Factbase::Taped.new(input) }
  end

  def test_context_with_lazy_taped
    _assert_context { |input| Factbase::LazyTaped.new(input) }
  end

  private

  def _assert_collision
    idx = {}
    maps = yield([
      { 'id' => 1, 'foo' => 41, 'bar' => 51, 'baz' => 61 },
      { 'id' => 2, 'foo' => 42, 'bar' => 52, 'baz' => 62 }
    ])
    [
      [[:foo], {}],
      [%i[$var], { 'var' => 'bar' }],
      [[:baz], {}]
    ].each do |operands, params|
      term = Factbase::Term.new(:unique, operands)
      index = Factbase::IndexedUnique.new(term, idx)
      tee = Factbase::Tee.new({}, params)
      found = index.predict(maps, nil, tee, [], maps.to_a)
      ids = found.to_a.map { |m| { id: m['id'] } }
      assert_equal([{ id: 1 }, { id: 2 }], ids, "operands: #{operands}. params: #{params}")
    end
  end

  def _assert_context
    maps = yield([
      { 'id' => 1, 'foo' => 41, 'bar' => 41 },
      { 'id' => 2, 'foo' => 42, 'bar' => 41 },
      { 'id' => 3, 'foo' => 42, 'bar' => 41 }
    ])
    [
      [[:bar], {}],
      [%i[$var], { 'var' => 'bar' }]
    ].each do |operands, params|
      [
        maps.to_a[1..],
        Factbase::Taped.new(maps.to_a[1..]),
        Factbase::LazyTaped.new(maps.to_a[1..])
      ].each do |tail|
        context = [[:eq, ['foo', 2]]]
        term = Factbase::Term.new(:unique, operands)
        index = Factbase::IndexedUnique.new(term, {})
        tee = Factbase::Tee.new({}, params)
        found = index.predict(maps, nil, tee, context, tail)
        ids = found.to_a.map { |m| { id: m['id'] } }
        assert_equal([{ id: 2 }], ids, "operands: #{operands}. params: #{params}. tail: #{tail.class}")
      end
    end
  end
end
