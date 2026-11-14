# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/eq'
require_relative '../../test__helper'

# Tests for the 'eq' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestEq < Factbase::Test
  def test_compares_equal
    assert(Factbase::Eq.new([:number, 42]).evaluate(fact('number' => 42), [], Factbase.new))
  end

  def test_compares_not_equal
    refute(Factbase::Eq.new([:number, 42]).evaluate(fact('number' => 100), [], Factbase.new))
  end

  def test_compares_numbers_with_many_values
    fb = Factbase.new
    fb.insert.id = 42
    fb.insert.id = 100
    ids = (1..20).to_a
    assert_empty(fb.query('(eq id $ids)').each(fb, 'ids' => ids).to_a)
    ids << 42
    assert_equal(1, fb.query('(eq id $ids)').each(fb, 'ids' => ids).to_a.size)
  end

  def test_compares_integer_and_float_equality
    fb = Factbase.new
    fb.insert.id = 42.0
    assert_equal(1, fb.query('(eq id $ids)').each(fb, 'ids' => [1, 2, 3, 42, 5, 6, 7, 8, 9, 10]).to_a.size)
    fb.insert.id = 15
    assert_equal(
      1,
      fb.query('(eq id $ids)').each(fb, 'ids' => [15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0]).to_a.size
    )
  end

  def test_compares_strings_with_many_values
    fb = Factbase.new
    fb.insert.tag = 'ruby'
    fb.insert.tag = 'python'
    assert_equal(
      1,
      fb.query('(eq tag $tags)').each(fb, 'tags' => %w[c java rust go elixir swift kotlin scala clojure ruby]).to_a.size
    )
  end

  def test_compares_times_with_many_values
    fb = Factbase.new
    now = Time.utc(2026, 10, 17, 12, 0, 0)
    fb.insert.when = Time.utc(2026, 10, 17, 12, 0, 0, 500_000)
    times = (1..10).map { |i| now - (i * 3600) }
    assert_empty(fb.query('(eq when $times)').each(fb, 'times' => times).to_a)
    times << now
    assert_equal(1, fb.query('(eq when $times)').each(fb, 'times' => times).to_a.size)
  end

  def test_compares_multi_values_on_left
    fb = Factbase.new
    f = fb.insert
    (1..10).each { |i| f.tags = i }
    assert_equal(1, fb.query('(eq tags 5)').each(fb).to_a.size)
    assert_empty(fb.query('(eq tags 99)').each(fb).to_a)
  end

  def test_compares_both_sides_large_multi_values
    fb = Factbase.new
    f = fb.insert
    (1..20).each { |i| f.nums = i }
    assert_equal(1, fb.query('(eq nums $candidates)').each(fb, 'candidates' => (15..35).to_a).to_a.size)
    assert_empty(fb.query('(eq nums $candidates)').each(fb, 'candidates' => (30..50).to_a).to_a)
  end

  def test_handles_duplicates_in_multi_values
    fb = Factbase.new
    f = fb.insert
    [7, 7, 7, 8, 8, 8, 9, 9, 9].each { |i| f.val = i }
    assert_equal(
      1,
      fb.query('(eq val $targets)').each(fb, 'targets' => [9, 9, 9, 10, 10, 11, 12, 13, 14, 15]).to_a.size
    )
    assert_empty(fb.query('(eq val $targets)').each(fb, 'targets' => [1, 1, 2, 2, 3, 3, 4, 4, 5, 5]).to_a)
  end

  def test_handles_nil_and_empty_values
    fb = Factbase.new
    fb.insert.id = 1
    assert_empty(fb.query('(eq missing $ids)').each(fb, 'ids' => (1..15).to_a).to_a)
    assert_empty(fb.query('(eq id $empty)').each(fb, 'empty' => []).to_a)
  end

  def test_compares_mixed_types_without_error
    fb = Factbase.new
    fb.insert.data = 'test'
    fb.insert.data = 42
    fb.insert.data = true
    fb.insert.data = 3.14
    assert_equal(
      2,
      fb.query('(eq data $mixed)').each(fb, 'mixed' => [1, 'test', 42.0, false, 'a', 'b', 'c', 'd', 'e']).to_a.size
    )
  end

  def test_compares_booleans_with_many_values
    fb = Factbase.new
    fb.insert.flag = true
    assert_equal(
      1,
      fb.query('(eq flag $flags)').each(
        fb,
        'flags' => [false, false, false, false, false, false, false, false, false, true]
      ).to_a.size
    )
  end

  def test_large_value_set_correctness
    fb = Factbase.new
    100.times { |i| fb.insert.code = i }
    assert_equal(50, fb.query('(eq code $sel)').each(fb, 'sel' => (50..150).to_a).to_a.size)
  end
end
