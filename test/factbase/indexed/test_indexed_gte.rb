# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../../lib/factbase/indexed/indexed_gte'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/term'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Indexed term 'gte' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedGte < Factbase::Test
  def test_keeps_the_order_the_facts_were_inserted_in
    term = Factbase::Term.new(:gte, [:num, 2])
    term.redress!(Factbase::IndexedTerm, idx: {})
    maps = Factbase::Taped.new(
      [
        { 'num' => [5], 'tag' => ['t0'] },
        { 'num' => [1], 'tag' => ['t1'] },
        { 'num' => [3], 'tag' => ['t2'] },
        { 'num' => [2], 'tag' => ['t3'] }
      ]
    )
    assert_equal(%w[t0 t2 t3], term.predict(maps, Factbase.new, {}).to_a.map { |m| m['tag'].first })
  end

  def test_orders_as_a_plain_factbase_does
    maps = [{ 'a' => [3] }, { 'a' => [0] }, { 'a' => [2] }, { 'a' => [1] }]
    assert_equal(
      Factbase.new(maps.map(&:dup)).query('(gte a 1)').each.to_a.map { |f| f['a'].first },
      Factbase::IndexedFactbase.new(
        Factbase.new(maps.map(&:dup))
      ).query('(gte a 1)').each.to_a.map { |f| f['a'].first },
      'the index must not reorder the facts of a range query'
    )
  end
end
