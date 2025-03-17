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
    n = term.predict(maps, {})
    assert_equal(2, n.size)
  end

  def test_predicts_on_exists
    term = Factbase::Term.new(:exists, [:foo])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7] }, { 'foo' => [22, 42] }, { 'foo' => [] }])
    n = term.predict(maps, {})
    assert_equal(3, n.size)
  end

  def test_predicts_on_and
    term = Factbase::Term.new(
      :and,
      [
        Factbase::Term.new(:eq, [:foo, 42]),
        Factbase::Term.new(:eq, [:bar, 7])
      ]
    )
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7], 'foo' => [22, 42] }, { 'foo' => [22, 42] }])
    n = term.predict(maps, {})
    assert_equal(1, n.size)
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
    n = term.predict(maps, {})
    assert_equal(3, n.size)
  end

  def test_predicts_on_others
    term = Factbase::Term.new(:boom, [])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'alpha' => [] }, {}])
    n = term.predict(maps, {})
    assert_equal(3, n.size)
  end
end
