# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/fuzz'
require_relative 'test__helper'

# Test for Factbase::Fuzz.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Author:: Philip Belousov (belousovfilip@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedAnd < Factbase::Test
  def test_make_generates_default_size
    fb = Factbase::Fuzz.make
    assert_equal(1000, fb.query('(always)').to_a.size)
  end

  def test_make_with_custom_size
    [0, 150].each do |count|
      fb = Factbase::Fuzz.make(count)
      assert_equal(count, fb.query('(always)').to_a.size)
    end
  end

  def test_feed_accumulates_facts
    total = 0
    fuzz = Factbase::Fuzz.new
    fb = Factbase::Fuzz.make(0)
    [0, 50, 100].each do |count|
      total += count
      fuzz.feed(fb, count)
      assert_equal(total, fb.size)
    end
  end

  def test_contains_all_required_fields
    fb = Factbase::Fuzz.make(100)
    found_empty = false
    found_filled = false
    fb.query('(always)').each do |fact|
      assert_kind_of(Integer, fact.number)
      assert_kind_of(Integer, fact.cost)
      assert_kind_of(Integer, fact.diff_size)
      assert_kind_of(Integer, fact.ready)
      assert_kind_of(String, fact.kind)
      assert_kind_of(String, fact.author)
      assert_kind_of(String, fact.state)
      assert_kind_of(String, fact.title)
      assert_kind_of(Float, fact.test_coverage)
      assert_kind_of(Time, fact.created_at)
      found_empty = true if fact['comments'].nil?
      found_filled = true unless fact['comments'].nil?
    end
    assert(found_empty, 'Should find at least one fact without comments')
    assert(found_filled, 'Should find at least one fact with comments')
  end
end
