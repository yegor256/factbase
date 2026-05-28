# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_one'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/lazy_taped'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/term'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Indexed term 'one' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedOne < Factbase::Test
  def test_predicts_on_one_with_array
    _assert_one { |input| input }
  end

  def test_predicts_on_one_with_taped
    _assert_one { |input| Factbase::Taped.new(input) }
  end

  def test_predicts_on_one_with_lazy_taped
    _assert_one { |input| Factbase::LazyTaped.new(input) }
  end

  def test_predict_decorator_persistence
    [
      { input: [{ 'foo' => [42] }], expected: Array },
      { input: Factbase::Taped.new([{ 'foo' => [42] }]), expected: Factbase::Taped },
      { input: Factbase::LazyTaped.new([{ 'foo' => [42] }]), expected: Factbase::Taped }
    ].each do |c|
      term = Factbase::Term.new(:one, [:foo])
      term.redress!(Factbase::IndexedTerm, idx: {})
      assert_kind_of(c[:expected], term.predict(c[:input], nil, {}), "Failed persistence for #{c[:input].class}")
    end
  end

  private

  def _assert_one
    [
      { input: [{ 'foo' => [42] }, { 'bar' => [1] }], expected: 1 },
      { input: [{ 'foo' => [42, 43] }], expected: 0 },
      { input: [{ 'bar' => [1] }], expected: 0 },
      { input: [{ 'foo' => [1] }, { 'foo' => [1, 2] }, { 'foo' => [3] }], expected: 2 }
    ].each do |c|
      maps = yield(c[:input])
      term = Factbase::Term.new(:one, [:foo])
      term.redress!(Factbase::IndexedTerm, idx: {})
      assert_equal(c[:expected], term.predict(maps, nil, {}).size, "Failed for #{maps.class} with #{c[:input]}")
    end
  end
end
