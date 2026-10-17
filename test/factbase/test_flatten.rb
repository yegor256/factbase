# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/flatten'

require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestFlatten < Factbase::Test
  def test_mapping
    to = Factbase::Flatten.new(
      [{ 'b' => [42], 'i' => 1 }, { 'a' => 33, 'i' => 0 }, { 'c' => %w[hey you], 'i' => 2 }],
      'i'
    ).it
    assert_equal(33, to[0]['a'])
    assert_equal(42, to[1]['b'])
    assert_equal(2, to[2]['c'].size)
  end

  def test_without_sorter
    assert_equal(33, Factbase::Flatten.new([{ 'b' => [42], 'i' => [44] }, { 'a' => 33 }], 'i').it[0]['a'])
  end

  def test_sorts_with_incompatible_types
    assert_equal(
      2,
      Factbase::Flatten.new([{ 'foo' => [42], 'i' => 1 }, { 'foo' => ['hello'], 'i' => 0 }], 'foo').it.size
    )
  end

  def test_sorts_numbers_in_their_own_order
    assert_equal(
      [1, 2, 10],
      Factbase::Flatten.new(
        [{ 'i' => [10] }, { 'i' => [2] }, { 'i' => [1] }], 'i'
      ).it.map { |m| m['i'] }
    )
  end

  def test_sorts_strings_alphabetically
    assert_equal(
      %w[a b c],
      Factbase::Flatten.new(
        [{ 'i' => ['c'] }, { 'i' => ['a'] }, { 'i' => ['b'] }], 'i'
      ).it.map { |m| m['i'] }
    )
  end

  def test_sorts_times_chronologically
    now = Time.now
    assert_equal(
      [now, now + 60],
      Factbase::Flatten.new([{ 't' => [now + 60] }, { 't' => [now] }], 't').it.map { |m| m['t'] }
    )
  end

  def test_sorts_values_of_mixed_kinds
    time = Time.at(1_000)
    assert_equal(
      [5_000, time, 'b'],
      Factbase::Flatten.new([{ 'x' => ['b'] }, { 'x' => [5_000] }, { 'x' => [time] }], 'x').it.map { |m| m['x'] }
    )
  end

  def test_sorts_mixed_kinds_numbers_times_and_strings
    t1 = Time.at(100)
    t2 = Time.at(200)
    facts = [
      { 'k' => ['zebra'] },
      { 'k' => [t2] },
      { 'k' => [500] },
      { 'k' => ['apple'] },
      { 'k' => [-10] },
      { 'k' => [t1] },
      { 'k' => [2.5] },
      { 'k' => [0] }
    ]
    assert_equal(
      [-10, 0, 2.5, 500, t1, t2, 'apple', 'zebra'],
      Factbase::Flatten.new(facts, 'k').it.map { |m| m['k'] }
    )
  end

  def test_sorts_integers_and_floats_before_times
    time = Time.at(50)
    facts = [{ 'val' => [time] }, { 'val' => [100.5] }, { 'val' => [25] }, { 'val' => [1_000] }, { 'val' => [-0.5] }]
    assert_equal([-0.5, 25, 100.5, 1_000, time], Factbase::Flatten.new(facts, 'val').it.map { |m| m['val'] })
  end

  def test_sorts_times_before_strings_lexicographically
    t1 = Time.at(10)
    t2 = Time.at(20)
    facts = [
      { 's' => ['000_starts_with_zero'] },
      { 's' => [t2] },
      { 's' => ['alphabet'] },
      { 's' => [t1] },
      { 's' => ['!punctuation'] }
    ]
    assert_equal(
      [t1, t2, '!punctuation', '000_starts_with_zero', 'alphabet'],
      Factbase::Flatten.new(facts, 's').it.map { |m| m['s'] }
    )
  end

  def test_sorts_times_that_differ_only_in_nanoseconds
    late = Time.at(1_800_000_000, 20, :nanosecond)
    early = Time.at(1_800_000_000, 10, :nanosecond)
    assert_equal(
      [early, late],
      Factbase::Flatten.new([{ 'when' => [late] }, { 'when' => [early] }], 'when').it.map { |m| m['when'] }
    )
  end
end
