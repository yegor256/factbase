# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedExistsShrink < Factbase::Test
  def test_answers_a_query_over_an_array_that_shrank
    assert_equal(asked('(one x)'), asked('(exists x)'))
  end

  def test_answers_a_query_over_an_array_that_shrank_by_one
    assert_equal(asked('(one x)', drop: 1), asked('(exists x)', drop: 1))
    assert_equal(4, asked('(exists x)', drop: 1))
    assert_equal(4, asked('(one x)', drop: 1))
  end

  def test_answers_a_query_over_an_array_after_one_fact_deleted
    ['(exists x)', '(one x)'].each do |q|
      maps = []
      5.times { |i| maps << { 'x' => [i] } }
      fb = Factbase::IndexedFactbase.new(Factbase.new)
      fb.query(q, maps).each(fb, {}).to_a
      maps.delete_at(2)
      assert_equal(4, fb.query(q, maps).each(fb, {}).to_a.size, "#{q} failed after deleting one fact")
    end
  end

  private

  def asked(query, drop: 3)
    maps = []
    5.times { |i| maps << { 'x' => [i] } }
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.query(query, maps).each(fb, {}).to_a
    maps.pop(drop)
    fb.query(query, maps).each(fb, {}).to_a.size
  end
end
