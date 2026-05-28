# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/lazy_taped'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/term'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Indexed term 'absent' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Author:: Philip Belousov (belousovfilip@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedAbsent < Factbase::Test
  def test_predicts_on_absent_with_array
    _assert_absent { |input| input }
  end

  def test_predicts_on_absent_with_taped
    _assert_absent { |input| Factbase::Taped.new(input) }
  end

  def test_predicts_on_absent_with_lazy_taped
    _assert_absent { |input| Factbase::LazyTaped.new(input) }
  end

  def test_predict_decorator_persistence
    [
      { input: [{ 'foo' => 42 }], expected: Array },
      { input: Factbase::Taped.new([{ 'bar' => 42 }]), expected: Factbase::Taped },
      { input: Factbase::LazyTaped.new([{ 'bar' => 42 }]), expected: Factbase::Taped }
    ].each do |c|
      term = Factbase::Term.new(:absent, [:foo])
      term.redress!(Factbase::IndexedTerm, idx: {})
      n = term.predict(c[:input], nil, {})
      assert_kind_of(c[:expected], n, "Expect #{c[:expected]}, but got #{n.class} for input #{c[:input].class}")
    end
  end

  private

  def _assert_absent
    [
      { input: [{ 'foo' => [42] }, { 'foo' => [42] }], expected: 0 },
      { input: [{ 'foo' => [42] }, { 'bar' => [42] }], expected: 1 },
      { input: [{ 'bar' => [42] }, { 'bar' => [42] }, { 'bar' => [1, 2] }], expected: 3 }
    ].each do |c|
      term = Factbase::Term.new(:absent, [:foo])
      term.redress!(Factbase::IndexedTerm, idx: {})
      assert_equal(c[:expected], term.predict(yield(c[:input]), nil, {}).size, "Failed on Taped for #{c[:input]}")
    end
  end
end
