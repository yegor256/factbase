# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Equality buckets contain each fact once after numeric normalization.
class TestIndexedEqNormalizedValues < Factbase::Test
  def test_keeps_distinct_facts_without_repeating_normalized_values
    raw = Factbase.new
    2.times do |id|
      fact = raw.insert
      fact.id = id
      fact.x = 2
      fact.x = 2.0
    end
    indexed = Factbase::IndexedFactbase.new(raw)
    ['(eq x 2)', '(eq x 2.0)', '(eq x $value)'].each do |expression|
      query = indexed.query(expression)
      2.times do
        assert_equal([0, 1], query.each(indexed, value: 2).map(&:id), expression)
      end
    end
    assert_equal(2, indexed.query('(eq x 2)').delete!)
    assert_equal(0, indexed.size)
  end
end
