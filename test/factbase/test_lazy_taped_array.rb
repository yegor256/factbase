# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase/lazy_taped'
require_relative '../../lib/factbase/lazy_taped_hash'
require_relative '../../lib/factbase/lazy_taped_array'

# Test for Factbase::LazyTaped::LazyTapedArray.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Author:: Philip Belousov (belousovfilip@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestLazyTapedArray < Factbase::Test
  def test_each
    arr, hash = wrap([1, 2, 3])
    sum = 0
    arr.each { |v| sum += v }
    assert_read(hash, 6, sum)
  end

  def test_read
    arr, hash = wrap([10, 20])
    assert_read(hash, 20, arr[1])
  end

  def test_to_a
    arr, hash = wrap([1, 2])
    assert_read(hash, [1, 2], arr.to_a)
  end

  def test_any
    arr, hash = wrap(%w[foo bar])
    assert_read(hash, true, arr.any?(/bar/))
    assert_read(hash, false, arr.any?(/baz/))
  end

  def test_uniq
    arr, hash, added = wrap([1, 1, 2])
    arr.uniq!
    assert_write(hash, added, [1, 2], arr.to_a)
  end

  def test_append
    arr, hash, added = wrap([1])
    arr << 2
    assert_write(hash, added, [1, 2], arr.to_a)
  end

  private

  def wrap(origin)
    added = []
    map = { 'foo' => origin }
    lt = Factbase::LazyTaped.new([map])
    hash = Factbase::LazyTaped::LazyTapedHash.new(map, lt, added)
    [Factbase::LazyTaped::LazyTapedArray.new(origin, 'foo', hash, added), hash, added]
  end

  def assert_read(hash, expected, actual)
    assert_equal(expected, actual)
    refute_predicate(hash, :copied?)
  end

  def assert_write(hash, added, expected, actual)
    assert_equal(expected, actual)
    refute_empty(added)
    assert_predicate(hash, :copied?)
  end
end
