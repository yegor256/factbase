# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Non-term operands of indexed logical queries.
class TestIndexedBooleanOperands < Factbase::Test
  def test_matches_plain_queries_with_properties_and_literals
    raw = Factbase.new
    [false, true].each_with_index do |enabled, x|
      fact = raw.insert
      fact.x = x
      fact.enabled = enabled
    end
    indexed = Factbase::IndexedFactbase.new(raw)
    [
      '(and enabled (eq x 1))',
      '(and (eq x 1) enabled)',
      '(or enabled (eq x 0))',
      '(or (eq x 0) enabled)',
      '(not enabled)',
      '(and true (eq x 1))',
      '(and false (eq x 1))',
      '(or true (eq x 0))',
      '(or false (eq x 0))',
      '(not true)',
      '(not false)'
    ].each do |query|
      assert_equal(raw.query(query).map(&:x), indexed.query(query).map(&:x), query)
    end
  end
end
