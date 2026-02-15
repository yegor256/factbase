# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/lazy_taped'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/indexed/indexed_gt'

# Indexed term 'gt' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedGt < Factbase::Test
  def test_predicts_on_gt
    term = Factbase::Term.new(:gt, [:foo, 42])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new(
      [
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

  def test_predicts_on_gt_with_floats
    term = Factbase::Term.new(:gt, [:foo, 50.5])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new(
      [
        { 'foo' => [50.6] },
        { 'foo' => [50.5] },
        { 'foo' => [49.9, 60.0] },
        { 'foo' => [30.1] },
        { 'bar' => [40] }
      ]
    )
    n = term.predict(maps, nil, {})
    assert_equal(2, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_gt_with_missing_parameter
    term = Factbase::Term.new(:gt, %i[sum $max_sum])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'sum' => [25] }])
    n = term.predict(maps, nil, {})
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predict_decorator_persistence
    [
      { input: [{ 'foo' => [40] }], expected: Array },
      { input: Factbase::Taped.new([{ 'foo' => [40] }]), expected: Factbase::Taped },
      { input: Factbase::LazyTaped.new([{ 'foo' => [30] }]), expected: Factbase::Taped }
    ].each do |c|
      term = Factbase::Term.new(:gt, [:foo, 30])
      idx = {}
      term.redress!(Factbase::IndexedTerm, idx:)
      n = term.predict(c[:input], nil, {})
      assert_kind_of(c[:expected], n, "Expect #{c[:expected]}, but got #{n.class} for input #{c[:input].class}")
    end
  end

  def test_predicts_on_gt_below_threshold
    term = Factbase::Term.new(:gt, [:bar, 25])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new(
      [
        { 'bar' => [10] },
        { 'bar' => [15] },
        { 'bar' => [20] }
      ]
    )
    n = term.predict(maps, nil, {})
    assert_empty(n)
  end
end
