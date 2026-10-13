# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/cached/cached_factbase'
require_relative '../../test__helper'

# Stateful terms nested inside cached expressions.
class TestCachedStatefulTerms < Factbase::Test
  def test_evaluates_constant_stateful_operands_for_each_fact
    raw = Factbase.new
    3.times { |x| raw.insert.x = x }
    cached = Factbase::CachedFactbase.new(raw)
    ['(not (unique 1))', '(eq (prev 1) 1)'].each do |expression|
      query = cached.query(expression)
      assert_equal([1, 2], raw.query(expression).map(&:x), expression)
      assert_equal([1, 2], query.map(&:x), expression)
      assert_equal([1, 2], query.map(&:x), expression)
      refute_predicate(cached.to_term(expression), :static?, expression)
    end
  end
end
