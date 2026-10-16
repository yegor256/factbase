# frozen_string_literal: true

require_relative '../../lib/factbase/lazy_taped'
require_relative '../../lib/factbase/lazy_taped_array'
require_relative '../../lib/factbase/lazy_taped_hash'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

# Test for Factbase::LazyTaped::LazyTapedArray.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Author:: Philip Belousov (belousovfilip@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestLazyTapedArray < Factbase::Test
  def test_time_reads_are_detached
    arr, hash, added = wrap([Time.utc(2026, 10, 13, 12)])
    arr[0].localtime('+03:00')
    arr.to_a.first.localtime('+03:00')
    arr.each { |time| time.localtime('+03:00') }
    arr.any? { |time| time.localtime('+03:00') }
    assert_equal(0, arr[0].utc_offset)
    assert_empty(added)
    refute_predicate(hash, :copied?)
  end

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

  def test_does_not_expose_mutable_strings
    arr, hash, added = wrap([+'foo'])
    assert_raises(FrozenError) { arr[0] << 'bar' }
    assert_raises(FrozenError) { arr.each { |item| item << 'bar' } }
    assert_raises(FrozenError) { arr.to_a[0] << 'bar' }
    assert_raises(FrozenError) { arr.any? { |item| item << 'bar' } }
    assert_equal('foo', arr[0])
    assert_empty(added)
    refute_predicate(hash, :copied?)
  end

  def test_uniq
    arr, hash, added = wrap([1, 1, 2])
    arr.uniq!
    assert_write(hash, added, [1, 2], arr.to_a)
  end

  def test_uniq_of_unique_values_changes_nothing
    arr, hash, added = wrap([1, 2])
    assert_nil(arr.uniq!)
    assert_empty(added)
    refute_predicate(hash, :copied?)
  end

  def test_append
    arr, hash, added = wrap([1])
    arr << 2
    assert_write(hash, added, [1, 2], arr.to_a)
  end

  def test_any_with_a_false_pattern
    arr, hash = wrap([false])
    assert_read(hash, true, arr.any?(false))
    arr, hash = wrap([true])
    assert_read(hash, false, arr.any?(false))
  end

  private

  def wrap(origin)
    added = []
    map = { 'foo' => origin }
    hash = Factbase::LazyTaped::LazyTapedHash.new(map, Factbase::LazyTaped.new([map]), added)
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
