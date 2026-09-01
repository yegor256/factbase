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
    assert_equal(
      3,
      Factbase::Flatten.new(
        [{ 'x' => ['b'] }, { 'x' => [1] }, { 'x' => [Time.now] }], 'x'
      ).it.size
    )
  end
end
