# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/taped'
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
