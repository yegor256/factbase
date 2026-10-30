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
    _assert_yields('gt', 1, 1)
  end

  def test_gte_yields_a_multi_valued_fact_once
    _assert_yields('gte', 1, 1)
  end

  def test_lt_yields_a_multi_valued_fact_once_per_fact
    _assert_yields('lt', 10, 2)
  end

  def test_lte_yields_a_multi_valued_fact_once_per_fact
    _assert_yields('lte', 10, 2)
  end

  private

  def _assert_yields(operator, limit, expected)
    plain = Factbase.new
    indexed = Factbase::IndexedFactbase.new(Factbase.new)
    [plain, indexed].each do |fb|
      first = fb.insert
      first.x = 5
      first.x = 6
      first.x = 7
      fb.insert.x = 0
    end
    query = "(#{operator} x #{limit})"
    assert_equal(expected, indexed.query(query).each(indexed, {}).count, "Indexed #{query} yields too many facts")
    assert_equal(
      plain.query(query).each(plain, {}).count,
      indexed.query(query).each(indexed, {}).count,
      "Indexed #{query} disagrees with the plain factbase"
    )
  end
end
