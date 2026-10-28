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
  def test_retained_array_reads_writes_from_another_handle
    base = Factbase.new
    base.insert.x = 1
    base.txn do |tx|
      values = tx.each.first['x']
      tx.query('(always)').first.x = 2
      assert_equal([1, 2], values.to_a)
      assert_equal([1, 2], values.each.to_a)
      assert_equal(2, values[1])
      assert_equal(2, values.size)
      assert(values.any?(2))
    end
  end

  def test_retained_array_removes_new_duplicates
    base = Factbase.new
    base.insert.x = 1
    churn =
      base.txn do |tx|
        values = tx.each.first['x']
        assert_equal([1], values.to_a)
        tx.query('(always)').first.x = 1
        assert_equal([1], values.uniq!)
      end
    assert_equal([1], base.each.first['x'])
    assert_equal([0, 0, 1], [churn.inserted, churn.deleted, churn.added])
  end

  def test_retained_array_mutations_roll_back
    base = Factbase.new
    base.insert.x = 1
    base.txn do |tx|
      values = tx.each.first['x']
      tx.query('(always)').first.x = 2
      assert_equal([1, 2], values.to_a)
      values << 3
      raise(Factbase::Rollback)
    end
    assert_equal([1], base.each.first['x'])
  end

  def test_each_retains_the_wrapper_for_chained_writes
    arr, hash, added = wrap([1])
    assert_same(arr, arr.each(&:itself))
    arr.each(&:itself) << 2
    assert_write(hash, added, [1, 2], arr.to_a)
  end

  def test_chained_iteration_write_rolls_back
    base = Factbase.new
    base.insert.x = 1
    base.txn do |tx|
      tx.each { |map| map['x'].each(&:itself) << 2 }
      raise(Factbase::Rollback)
    end
    assert_equal([1], base.each.first['x'])
  end

  def test_chained_iteration_write_commits_after_copying
    base = Factbase.new
    2.times do |id|
      fact = base.insert
      fact.id = id
      fact.x = 1
    end
    base.txn do |tx|
      tx.query('(eq id 0)').first.x = 2
      tx.each do |map|
        next unless map['id'].to_a == [1]
        map['x'].each(&:itself) << 3
      end
    end
    assert_equal([1, 3], base.query('(eq id 1)').first['x'])
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

  def test_reads_like_an_array
    arr, hash = wrap([42, 7])
    assert_read(hash, true, arr.include?(42))
    assert_read(hash, 42, arr.first)
    assert_read(hash, 2, arr.size)
    assert_read(hash, [7, 42], arr.sort)
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
