# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/lazy_taped'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestLazyTaped < Factbase::Test
  def test_tracks_insertion
    t = Factbase::LazyTaped.new([])
    t << {}
    assert_equal(1, t.inserted.size)
  end

  def test_does_not_copy_on_read
    original = [{ foo: [1, 2] }]
    t = Factbase::LazyTaped.new(original)
    assert_equal(1, t.size)
    t.each { |m| m['foo'] }
    assert_empty(t.pairs)
  end

  def test_copies_on_insert
    original = [{ foo: [1] }]
    t = Factbase::LazyTaped.new(original)
    t << { bar: [2] }
    refute_empty(t.pairs)
    assert_equal(2, t.size)
  end

  def test_copies_on_property_set
    original = [{ 'foo' => [1] }]
    t = Factbase::LazyTaped.new(original)
    t.each { |m| m['bar'] = 42 }
    refute_empty(t.pairs)
    assert_equal(1, t.added.size)
    assert_nil(original[0]['bar'], 'Original should not be modified')
  end

  def test_copies_on_array_append
    original = [{ 'foo' => [1] }]
    t = Factbase::LazyTaped.new(original)
    t.each { |m| m['foo'] << 2 }
    refute_empty(t.pairs)
    assert_equal(1, t.added.size)
    assert_equal([1], original[0]['foo'], 'Original should not be modified')
    # Copied version should have the new value
    modified = t.find_by_object_id(t.added.first)
    assert_equal([1, 2], modified['foo'])
  end

  def test_copies_on_delete
    original = [{ foo: [1] }, { bar: [2] }]
    t = Factbase::LazyTaped.new(original)
    t.delete_if { |m| m[:foo] }
    refute_empty(t.pairs)
    assert_equal(1, t.deleted.size)
    assert_equal(1, t.size)
  end

  def test_joins_with_empty
    t = Factbase::LazyTaped.new([{ foo: 'yes' }])
    t &= []
    assert_equal(0, t.size)
  end

  def test_joins_with_non_empty
    t = Factbase::LazyTaped.new([{ foo: 'yes' }])
    t &= [{ bar: 'no' }]
    assert_equal(0, t.size)
  end

  def test_disjoins_with_empty
    t = Factbase::LazyTaped.new([{ bar: 'oops' }])
    t |= []
    assert_equal(1, t.size)
  end

  def test_disjoins_with_non_empty
    t = Factbase::LazyTaped.new([{ bar: 'oops' }])
    t |= [{ bar: 'no' }]
    assert_equal(2, t.size)
  end

  def test_to_a_without_copy
    original = [{ foo: 1 }, { bar: 2 }]
    t = Factbase::LazyTaped.new(original)
    assert_equal(original, t.to_a)
  end

  def test_to_a_after_modification
    original = [{ 'foo' => [1] }]
    t = Factbase::LazyTaped.new(original)
    t.each { |m| m['bar'] = 42 }
    arr = t.to_a
    assert_equal(1, arr.size)
    assert_equal(42, arr[0]['bar'])
  end

  def test_find_by_object_id
    t = Factbase::LazyTaped.new([])
    map = { 'test' => [1] }
    t << map
    found = t.find_by_object_id(map.object_id)
    assert_equal(map, found)
  end

  def test_enumerable_without_block
    t = Factbase::LazyTaped.new([{ a: 1 }, { b: 2 }])
    enum = t.each
    assert_instance_of(Enumerator, enum)
    assert_equal(2, enum.count)
  end

  def test_tracks_addition_uniquely
    original = [{ 'f' => [5] }]
    t = Factbase::LazyTaped.new(original)
    t.each do |m|
      m['bar'] = 66
      m['foo'] = 77
    end
    assert_equal(1, t.added.size)
  end

  def test_array_uniq_triggers_copy
    original = [{ 'foo' => [1, 1, 2] }]
    t = Factbase::LazyTaped.new(original)
    t.each { |m| m['foo'].uniq! }
    refute_empty(t.pairs)
    assert_equal(1, t.added.size)
    assert_equal([1, 1, 2], original[0]['foo'], 'Original should not be modified')
  end

  def test_array_any
    original = [{ 'foo' => [1, 2, 3] }]
    t = Factbase::LazyTaped.new(original)
    found = false
    t.each { |m| found = m['foo'].any?(2) }
    assert(found)
  end

  def test_array_index_access
    original = [{ 'foo' => [10, 20, 30] }]
    t = Factbase::LazyTaped.new(original)
    result = nil
    t.each { |m| result = m['foo'][1] }
    assert_equal(20, result)
  end

  def test_array_to_a
    original = [{ 'foo' => [1, 2] }]
    t = Factbase::LazyTaped.new(original)
    arr = nil
    t.each { |m| arr = m['foo'].to_a }
    assert_equal([1, 2], arr)
  end

  def test_array_each_enumerable
    original = [{ 'foo' => [1, 2, 3] }]
    t = Factbase::LazyTaped.new(original)
    sum = 0
    t.each { |m| m['foo'].each { |v| sum += v } }
    assert_equal(6, sum)
  end

  def test_hash_keys
    original = [{ 'foo' => [1], 'bar' => [2] }]
    t = Factbase::LazyTaped.new(original)
    keys = nil
    t.each { |m| keys = m.keys }
    assert_equal(%w[foo bar], keys)
  end

  def test_hash_map
    original = [{ 'foo' => [1], 'bar' => [2] }]
    t = Factbase::LazyTaped.new(original)
    result = nil
    t.each { |m| result = m.transform_values(&:first) }
    assert_equal({ 'foo' => 1, 'bar' => 2 }, result)
  end

  def test_read_only_txn_does_not_copy
    fb = Factbase.new
    fb.insert.foo = 42
    fb.insert.bar = 55
    # This transaction only reads, should not trigger copy
    churn =
      fb.txn do |fbt|
        fbt.query('(always)').each.to_a
      end
    assert_equal(0, churn.to_i)
  end

  def test_modifying_txn_copies_lazily
    fb = Factbase.new
    fb.insert.foo = 42
    churn =
      fb.txn do |fbt|
        fbt.query('(always)').each { |f| f.bar = 99 }
      end
    assert_equal(1, churn.to_i)
    fact = fb.query('(always)').each.to_a.first
    assert_equal(42, fact.foo)
    assert_equal(99, fact.bar)
  end

  def test_insert_in_txn
    fb = Factbase.new
    churn =
      fb.txn do |fbt|
        fbt.insert.foo = 123
      end
    assert_equal(1, churn.to_i)
    assert_equal(1, fb.size)
    assert_equal(123, fb.query('(always)').each.to_a.first.foo)
  end

  def test_delete_in_txn
    fb = Factbase.new
    fb.insert.foo = 1
    fb.insert.foo = 2
    churn =
      fb.txn do |fbt|
        fbt.query('(eq foo 1)').delete!
      end
    assert_equal(1, churn.to_i)
    assert_equal(1, fb.size)
    assert_equal(2, fb.query('(always)').each.to_a.first.foo)
  end

  def test_rollback_does_not_modify
    fb = Factbase.new
    fb.insert.foo = 42
    fb.txn do |fbt|
      fbt.query('(always)').each { |f| f.bar = 99 }
      raise Factbase::Rollback
    end
    fact = fb.query('(always)').each.to_a.first
    assert_equal(42, fact.foo)
    assert_raises(StandardError) { fact.bar }
  end
end
