# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_and'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/term'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Indexed term 'and' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedAnd < Factbase::Test
  def test_predicts_on_and
    term = Factbase::Term.new(:and, [Factbase::Term.new(:eq, [:foo, 42]), Factbase::Term.new(:eq, %i[bar $jeff])])
    term.redress!(Factbase::IndexedTerm, idx: {})
    n = term.predict(
      Factbase::Taped.new(
        [
          { 'foo' => [42] }, { 'bar' => [7], 'foo' => [22, 42] },
          { 'foo' => [22, 42] }
        ]
      ), nil, Factbase::Tee.new({}, { 'jeff' => [7] })
    )
    assert_equal(1, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_single_and
    term = Factbase::Term.new(:and, [Factbase::Term.new(:eq, [:foo, 42])])
    term.redress!(Factbase::IndexedTerm, idx: {})
    assert_equal(
      1,
      term.predict(Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7], 'foo' => [4] }]), nil, {}).size
    )
  end

  def test_predicts_on_and_returns_nil
    term = Factbase::Term.new(
      :and,
      [
        Factbase::Term.new(:boom, []),
        Factbase::Term.new(:eq, [:foo, 42]),
        Factbase::Term.new(:eq, [:bar, 7])
      ]
    )
    term.redress!(Factbase::IndexedTerm, idx: {})
    assert_nil(term.predict(Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7] }]), nil, {}))
  end
end
