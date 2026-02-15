# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/lazy_taped'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/indexed/indexed_eq'

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
      idx = {}
      maps = c[:input]
      term = Factbase::Term.new(:eq, [:foo, 42])
      term.redress!(Factbase::IndexedTerm, idx:)
      n = term.predict(maps, nil, {})
      assert_equal(c[:expected], n.size, "Failed on Array for #{c[:input]}")
    end
  end

  def test_predicts_on_eq_with_taped
    [
      { input: [{ 'foo' => [42] }, { 'bar' => [1] }], expected: 1 },
      { input: [{ 'foo' => [42] }, { 'foo' => [42] }, { 'foo' => [1, 42] }], expected: 3 }
    ].each do |c|
      idx = {}
      maps = Factbase::Taped.new(c[:input])
      term = Factbase::Term.new(:eq, [:foo, 42])
      term.redress!(Factbase::IndexedTerm, idx:)
      n = term.predict(maps, nil, {})
      assert_equal(c[:expected], n.size, "Failed on Taped for #{c[:input]}")
    end
  end

  def test_predicts_on_eq_with_lazy_taped
    [
      { input: [{ 'foo' => [42] }, { 'bar' => [1] }], expected: 1 },
      { input: [{ 'foo' => [42] }, { 'foo' => [42] }, { 'foo' => [1, 42] }], expected: 3 }
    ].each do |c|
      idx = {}
      maps = Factbase::LazyTaped.new(c[:input])
      term = Factbase::Term.new(:eq, [:foo, 42])
      term.redress!(Factbase::IndexedTerm, idx:)
      n = term.predict(maps, nil, {})
      assert_equal(c[:expected], n.size, "Failed on LazyTaped for #{c[:input]}")
    end
  end

  def test_predict_decorator_persistence
    [
      { input: [{ 'foo' => [42] }], expected: Array },
      { input: Factbase::Taped.new([{ 'foo' => [42] }]), expected: Factbase::Taped },
      { input: Factbase::LazyTaped.new([{ 'foo' => [42] }]), expected: Factbase::Taped }
    ].each do |c|
      term = Factbase::Term.new(:eq, [:foo, 42])
      idx = {}
      term.redress!(Factbase::IndexedTerm, idx:)
      n = term.predict(c[:input], nil, {})
      assert_kind_of(c[:expected], n, "Expect #{c[:expected]}, but got #{n.class} for input #{c[:input].class}")
    end
  end
end
