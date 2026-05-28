# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_lt'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/lazy_taped'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/term'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Indexed term 'lt' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedLt < Factbase::Test
  def test_predicts_on_lt
    term = Factbase::Term.new(:lt, [:foo, 42])
    term.redress!(Factbase::IndexedTerm, idx: {})
    n = term.predict(
      Factbase::Taped.new(
        [
          { 'foo' => [10] },
          { 'foo' => [43] },
          { 'foo' => [42] },
          { 'foo' => [100, 5] },
          { 'bar' => [50] },
          { 'foo' => [41, 42, 43] }
        ]
      ), nil, {}
    )
    assert_equal(3, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_lt_with_floats
    term = Factbase::Term.new(:lt, [:foo, 50.5])
    term.redress!(Factbase::IndexedTerm, idx: {})
    n = term.predict(
      Factbase::Taped.new(
        [
          { 'foo' => [50.0] },
          { 'foo' => [50.5] },
          { 'foo' => [50.6] },
          { 'foo' => [49.9, 60.0] },
          { 'foo' => [30.1] },
          { 'bar' => [40] }
        ]
      ), nil, {}
    )
    assert_equal(3, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_lt_with_missing_parameter
    term = Factbase::Term.new(:lt, %i[age $max_age])
    term.redress!(Factbase::IndexedTerm, idx: {})
    assert_kind_of(Factbase::Taped, term.predict(Factbase::Taped.new([{ 'age' => [25] }]), nil, {}))
  end

  def test_predict_decorator_persistence
    [
      { input: [{ 'foo' => [40] }], expected: Array },
      { input: Factbase::Taped.new([{ 'foo' => [20] }]), expected: Factbase::Taped },
      { input: Factbase::LazyTaped.new([{ 'foo' => [20] }]), expected: Factbase::Taped }
    ].each do |c|
      term = Factbase::Term.new(:lt, [:foo, 30])
      term.redress!(Factbase::IndexedTerm, idx: {})
      n = term.predict(c[:input], nil, {})
      assert_kind_of(c[:expected], n, "Expect #{c[:expected]}, but got #{n.class} for input #{c[:input].class}")
    end
  end

  def test_predicts_on_lt_above_threshold
    term = Factbase::Term.new(:lt, [:foo, 5])
    term.redress!(Factbase::IndexedTerm, idx: {})
    assert_empty(
      term.predict(
        Factbase::Taped.new([{ 'foo' => [10] }, { 'foo' => [15] }, { 'foo' => [20] }]), nil,
        {}
      )
    )
  end
end
