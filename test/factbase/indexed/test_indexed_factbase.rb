# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'elapsed'
require 'loog'
require 'timeout'
require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestIndexedFactbase < Factbase::Test
  def test_queries_after_update
    origin = Factbase.new
    fb = Factbase::IndexedFactbase.new(origin)
    fb.insert.foo = 42
    fb.query('(exists foo)').each do |f|
      f.bar = 33
    end
    refute_empty(origin.query('(exists bar)').each.to_a)
    refute_empty(fb.query('(exists bar)').each.to_a)
  end

  def test_queries_after_update_in_txn
    [
      '(exists boom)',
      '(one boom)',
      '(and (exists boom) (exists boom))',
      '(and (exists boom) (exists boom) (exists boom))',
      '(and (one boom) (one boom))',
      '(and (one boom) (one foo))',
      '(and (one boom) (one boom) (one boom))',
      '(and (one boom) (one boom) (one boom) (one foo))',
      '(and (one boom) (exists boom))',
      '(and (exists boom) (one boom) (one boom))',
      '(and (exists boom) (exists boom) (one boom))',
      '(and (eq foo 42) (exists boom) (one boom) (not (exists bar)))'
    ].each do |q|
      origin = Factbase.new
      fb = Factbase::IndexedFactbase.new(origin)
      f = fb.insert
      f.foo = 42
      f.boom = 33
      fb.txn do |fbt|
        fbt.query(q).each do |n|
          n.bar = n.foo + 1
        end
      end
      refute_empty(origin.query('(exists bar)').each.to_a, q)
      refute_empty(fb.query('(exists bar)').each.to_a, q)
    end
  end

  def test_queries_after_insert_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.txn(&:insert)
    refute_empty(fb.query('(always)').each.to_a)
  end

  def test_works_with_huge_dataset
    fb = Factbase.new
    fb = Factbase::IndexedFactbase.new(fb)
    10_000.times do |i|
      fb.insert.then do |f|
        f.id = i
        f.foo = [42, 1, 256, 7, 99].sample
        f.bar = [42, 13, 88, 19, 93].sample
        f.rarely = rand if rand > 0.95
        f.often = rand if rand > 0.05
      end
    end
    [
      '(and (eq foo 42) (exists bar))',
      '(and (eq foo 42) (exists rarely))',
      '(and (eq foo 42) (exists often))',
      '(and (eq foo 42) (exists often) (exists bar) (absent rarely))',
      '(and (eq foo 42) (empty (eq foo 888)))',
      '(and (eq foo 42) (empty (eq foo $id)))',
      '(and (eq foo 42) (empty (eq foo $often)))',
      '(and (eq foo 42) (empty (and (eq foo $often) (gt foo 43))))',
      '(and (eq foo 42) (empty (and (eq foo 42) (eq bar 42) (eq id -1))))',
      '(and (eq foo 42) (empty (exists another)))'
    ].each do |q|
      Timeout.timeout(4) do
        elapsed(Loog::NULL, good: q) do
          refute_empty(fb.query(q).each.to_a)
        end
      end
    end
  end

  def test_export_and_import_with_index
    fb1 = Factbase::IndexedFactbase.new(Factbase.new)
    fb1.insert.foo = 42
    fb1.insert.bar = 13
    assert_equal(1, fb1.query('(eq foo 42)').each.to_a.size)
    data = fb1.export
    fb2 = Factbase::IndexedFactbase.new(Factbase.new)
    fb2.import(data)
    assert_equal(2, fb2.size)
    assert_equal(1, fb2.query('(eq foo 42)').each.to_a.size)
    assert_equal(1, fb2.query('(eq bar 13)').each.to_a.size)
  end

  def test_export_preserves_index
    populate =
      lambda do |fb|
        1000.times do |i|
          fb.insert.then do |f|
            f.id = i
            f.value = i * 2
          end
        end
      end
    fb1 = Factbase::IndexedFactbase.new(Factbase.new)
    populate.call(fb1)
    fb1.query('(eq value 100)').each.to_a
    fb1.query('(gt id 500)').each.to_a
    fb1.query('(exists value)').each.to_a
    data_with_index = fb1.export
    unmarshalled = Marshal.load(data_with_index)
    assert(unmarshalled.key?(:idx), 'Exported data should contain :idx key')
    assert_kind_of(Hash, unmarshalled[:idx], 'Index should be a Hash')
    refute_empty(unmarshalled[:idx], 'Index should not be empty after queries')
    fb2 = Factbase::IndexedFactbase.new(Factbase.new)
    fb2.import(data_with_index)
    assert_equal(1, fb2.query('(eq value 100)').each.to_a.size)
    assert_equal(499, fb2.query('(gt id 500)').each.to_a.size)
    assert_equal(1000, fb2.query('(exists value)').each.to_a.size)
    fb3 = Factbase::IndexedFactbase.new(Factbase.new)
    populate.call(fb3)
    data_without_index = fb3.export
    unmarshalled_no_idx = Marshal.load(data_without_index)
    assert_empty(unmarshalled_no_idx[:idx], 'Index should be empty without queries')
    assert_operator(data_with_index.size, :>, data_without_index.size, 'Export with index should be larger')
  end

  def test_insert_clears_index
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.query('(eq foo 42)').each.to_a
    data = fb.export
    unmarshalled = Marshal.load(data)
    assert_kind_of(Hash, unmarshalled[:idx])
    refute_empty(unmarshalled[:idx])
    fb2 = Factbase::IndexedFactbase.new(Factbase.new)
    fb2.import(data)
    fb2.insert.bar = 13
    data2 = fb2.export
    unmarshalled2 = Marshal.load(data2)
    assert_kind_of(Hash, unmarshalled2[:idx])
    assert_empty(unmarshalled2[:idx])
  end

  def test_import_backward_compatibility
    fb1 = Factbase.new
    fb1.insert.foo = 42
    fb1.insert.bar = 13
    old_format_data = fb1.export
    fb2 = Factbase::IndexedFactbase.new(Factbase.new)
    fb2.import(old_format_data)
    assert_equal(2, fb2.size)
    assert_equal(1, fb2.query('(eq foo 42)').each.to_a.size)
    assert_equal(1, fb2.query('(eq bar 13)').each.to_a.size)
  end

  def test_import_empty_raises_error
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    assert_raises(StandardError) do
      fb.import('')
    end
  end

  def test_index_does_not_grow_unbounded_during_transactions
    idx = {}
    fb = Factbase::IndexedFactbase.new(Factbase.new, idx)
    fb.insert.foo = rand
    100.times do
      fb.txn do |fbt|
        fbt.query('(exists foo)').each(&:foo)
      end
    end
    assert_operator(
      idx.size, :<, 10,
      'Index must not accumulate stale entries across transactions'
    )
  end

  def test_multiple_import_accumulates
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 1
    fb1 = Factbase::IndexedFactbase.new(Factbase.new)
    fb1.insert.foo = 2
    fb.import(fb1.export)
    assert_equal(2, fb.size)
    assert_equal(2, fb.query('(exists foo)').each.to_a.size)
  end
end
