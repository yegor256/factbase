# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Indexed range terms over a fact that holds several values of one property.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedRangeManyValues < Factbase::Test
  def test_gt_yields_a_multi_valued_fact_once
    _assert_yields('(gt x 1)', 1)
  end

  def test_gte_yields_a_multi_valued_fact_once
    _assert_yields('(gte x 1)', 1)
  end

  def test_lt_yields_a_multi_valued_fact_once_per_fact
    _assert_yields('(lt x 10)', 2)
  end

  def test_lte_yields_a_multi_valued_fact_once_per_fact
    _assert_yields('(lte x 10)', 2)
  end

  def test_and_does_not_multiply_a_multi_valued_fact
    _assert_yields('(and (gt x 1) (lt x 10))', 1)
  end

  private

  def _assert_yields(query, expected)
    plain = Factbase.new
    idx = {}
    indexed = Factbase::IndexedFactbase.new(Factbase.new, idx)
    [plain, indexed].each do |fb|
      first = fb.insert
      first.x = 5
      first.x = 6
      first.x = 7
      fb.insert.x = 0
    end
    assert_equal(expected, indexed.query(query).each(indexed, {}).count, "Indexed #{query} yields too many facts")
    refute_empty(idx, "Indexed #{query} was declined by the index and the full scan decided it")
    assert_equal(
      plain.query(query).each(plain, {}).count,
      indexed.query(query).each(indexed, {}).count,
      "Indexed #{query} disagrees with the plain factbase"
    )
  end
end
