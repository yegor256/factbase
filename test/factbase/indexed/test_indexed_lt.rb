# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/indexed/indexed_lt'

# Indexed term 'lt' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestIndexedLt < Factbase::Test
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
end
