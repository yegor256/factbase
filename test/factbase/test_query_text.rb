# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/cached/cached_factbase'
require_relative '../test__helper'

# Query text must not expose the mutable identity used by the cache.
class TestQueryText < Factbase::Test
  def test_editing_plain_query_text_preserves_its_expression
    fb = Factbase.new
    fb.insert.x = 1
    query = fb.query('(eq x 1)')
    text = query.to_s
    text.replace('(eq x 2)')
    assert_equal('(eq x 2)', text)
    assert_equal('(eq x 1)', query.to_s)
    assert_equal([1], query.each.map(&:x))
  end

  def test_editing_term_text_preserves_queries_built_from_the_term
    fb = Factbase.new
    fb.insert.x = 1
    term = fb.to_term('(eq x 1)')
    term.to_s.replace('(eq x 2)')
    query = fb.query(term)
    assert_equal('(eq x 1)', query.to_s)
    assert_equal([1], query.each.map(&:x))
  end

  def test_editing_cached_query_text_does_not_poison_another_query
    [false, true].each do |warm|
      fb = Factbase::CachedFactbase.new(Factbase.new)
      fb.insert.x = 1
      fb.insert.x = 2
      query = fb.query('(eq x 1)')
      query.each.to_a if warm
      query.to_s.replace('(eq x 2)')
      assert_equal([1], query.each.map(&:x))
      assert_equal([2], fb.query('(eq x 2)').each.map(&:x))
      assert_equal('(eq x 1)', query.to_s)
    end
  end

  def test_editing_scalar_query_text_does_not_poison_another_query
    fb = Factbase::CachedFactbase.new(Factbase.new)
    query = fb.query('(plus 1 2)')
    query.to_s.replace('(plus 2 2)')
    assert_equal(3, query.one)
    assert_equal(4, fb.query('(plus 2 2)').one)
    assert_equal('(plus 1 2)', query.to_s)
  end
end
