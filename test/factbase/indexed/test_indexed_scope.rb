# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Test that a query must not reuse an index built over a different maps array.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedScope < Factbase::Test
  def test_answers_absent_over_a_subset_before_the_whole_factbase
    _assert_scope('(absent y)')
  end

  def test_answers_exists_over_a_subset_before_the_whole_factbase
    _assert_scope('(exists x)')
  end

  def test_answers_one_over_a_subset_before_the_whole_factbase
    _assert_scope('(one x)')
  end

  private

  def _assert_scope(query)
    idx = {}
    fb = Factbase::IndexedFactbase.new(Factbase.new, idx)
    4.times { |i| fb.insert.x = i }
    fb.insert.y = 1
    subset = fb.to_enum(:each).to_a[2..]
    assert_equal(3, subset.size, 'The subset must stay three of the five facts')
    answers = [fb.query(query, subset).each.to_a.size, fb.query(query).each.to_a.size]
    assert_equal(2, answers[0], "#{query} answered wrong over the subset")
    assert_equal(
      2, idx.size,
      "#{query} kept one index entry for two different maps arrays, so the whole factbase reuses the subset"
    )
    assert_equal(4, answers[1], "#{query} answered with the index built over the subset")
  end
end
