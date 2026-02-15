# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/lazy_taped'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/indexed/indexed_not'

# Indexed term 'not' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedNot < Factbase::Test
  def test_predicts_on_not_returns_nil
    term = Factbase::Term.new(:not, [Factbase::Term.new(:some, [:bar, 22])])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [21] }])
    n = term.predict(maps, nil, {})
    assert_nil(n)
  end

  def test_predicts_on_not_with_array
    _assert_not { |input| input }
  end

  def test_predicts_on_not_with_taped
    _assert_not { |input| Factbase::Taped.new(input) }
  end

  def test_predicts_on_not_with_lazy_taped
    _assert_not { |input| Factbase::LazyTaped.new(input) }
  end

  def test_predict_decorator_persistence
    [
      { input: [{ 'foo' => [1] }], expected: Array },
      { input: Factbase::Taped.new([{ 'foo' => [1] }]), expected: Factbase::Taped },
      { input: Factbase::LazyTaped.new([{ 'foo' => [1] }]), expected: Factbase::Taped }
    ].each do |c|
      term = Factbase::Term.new(:not, [Factbase::Term.new(:eq, [:foo, 42])])
      idx = {}
      term.redress!(Factbase::IndexedTerm, idx:)
      n = term.predict(c[:input], nil, {})
      assert_kind_of(c[:expected], n, "Expect #{c[:expected]}, but got #{n.class}")
    end
  end

  private

  def _assert_not
    [
      { input: [{ 'foo' => [42] }, { 'bar' => [1] }], expected: 1 },
      { input: [{ 'foo' => [42] }, { 'foo' => [42, 1] }], expected: 0 },
      { input: [{ 'foo' => [1] }, { 'bar' => [1] }, { 'bar' => [1] }], expected: 3 }
    ].each do |c|
      maps = yield(c[:input])
      term = c[:term] || Factbase::Term.new(:not, [Factbase::Term.new(:eq, [:foo, 42])])
      term.redress!(Factbase::IndexedTerm, idx: {})
      n = term.predict(maps, nil, {})
      assert_equal(c[:expected], n.size, "Failed for #{maps.class}")
    end
  end
end
