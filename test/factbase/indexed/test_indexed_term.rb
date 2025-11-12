# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/indexed/indexed_term'

# Term test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestIndexedTerm < Factbase::Test
  def test_predicts_on_eq
    term = Factbase::Term.new(:eq, [:foo, 42])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7] }, { 'foo' => [22, 42] }, { 'foo' => [] }])
    n = term.predict(maps, nil, {})
    assert_equal(2, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_not
    term = Factbase::Term.new(:not, [Factbase::Term.new(:eq, [:foo, 42])])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7], 'foo' => [22, 42] }, { 'foo' => [22] }])
    n = term.predict(maps, nil, {})
    assert_equal(1, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_and
    term = Factbase::Term.new(
      :and,
      [
        Factbase::Term.new(:eq, [:foo, 42]),
        Factbase::Term.new(:eq, %i[bar $jeff])
      ]
    )
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7], 'foo' => [22, 42] }, { 'foo' => [22, 42] }])
    n = term.predict(maps, nil, Factbase::Tee.new({}, { 'jeff' => [7] }))
    assert_equal(1, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_single_and
    term = Factbase::Term.new(:and, [Factbase::Term.new(:eq, [:foo, 42])])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7], 'foo' => [4] }])
    assert_equal(1, term.predict(maps, nil, {}).size)
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
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7], 'foo' => [22, 42] }, { 'foo' => [22, 42] }])
    n = term.predict(maps, nil, {})
    assert_equal(3, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_others
    term = Factbase::Term.new(:boom, [])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'alpha' => [] }, {}])
    n = term.predict(maps, nil, {})
    assert_nil(n)
  end

  def test_predicts_on_gt
    term = Factbase::Term.new(:gt, [:foo, 42])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new(
      [
        { 'foo' => [10] },
        { 'foo' => [43] },
        { 'foo' => [42] },
        { 'foo' => [100, 5] },
        { 'bar' => [50] },
        { 'foo' => [41, 42, 43] }
      ]
    )
    n = term.predict(maps, nil, {})
    assert_equal(3, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_lt
    term = Factbase::Term.new(:lt, [:foo, 42])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new(
      [
        { 'foo' => [10] },
        { 'foo' => [43] },
        { 'foo' => [42] },
        { 'foo' => [100, 5] },
        { 'bar' => [50] },
        { 'foo' => [41, 42, 43] }
      ]
    )
    n = term.predict(maps, nil, {})
    assert_equal(3, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

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
    assert_equal(3, n.size)
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
  end
end
