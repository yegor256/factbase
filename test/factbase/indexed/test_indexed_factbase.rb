# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'elapsed'
require 'loog'
require 'timeout'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
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

  def test_queries_after_update_rollback_in_txn
    [
      '(absent bar)',
      '(unique foo)',
      '(exists foo)',
      '(or (one foo) (exists foo))',
      '(and (one foo) (exists foo))',
      '(and (one foo) (not (exists bar)))',
      '(not (eq foo 41))',
      '(one foo)',
      '(lte foo 42)',
      '(one foo)',
      '(eq foo 42)',
      '(gte foo 42)',
      '(gt foo 41)',
      '(lt foo 43)'
    ].each do |q|
      fb = Factbase::IndexedFactbase.new(Factbase.new)
      fb.insert.foo = 42
      fb.txn do |fbt|
        refute_empty(fbt.query(q).each.to_a, q)
        fbt.query(q).each do |f|
          f.foo = 43
        end
        raise(Factbase::Rollback)
      end
      refute_empty(fb.query(q).each.to_a, q)
      fb.query(q).each do |f|
        assert_equal([42], f['foo'], q)
      end
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
    fb2 = Factbase::IndexedFactbase.new(Factbase.new)
    fb2.import(fb1.export)
    assert_equal(2, fb2.size)
    assert_equal(1, fb2.query('(eq foo 42)').each.to_a.size)
    assert_equal(1, fb2.query('(eq bar 13)').each.to_a.size)
  end

  def test_exports_same_bytes_before_and_after_queries
    seed = Random.new_seed
    rnd = Random.new(seed)
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    total = rnd.rand(10..500)
    total.times { |i| fb.insert.id = i }
    assert_equal(
      fb.export,
      fb.tap do |f|
        f.query("(eq id #{rnd.rand(total)})").each.to_a
        f.query("(gt id #{rnd.rand(total)})").each.to_a
      end.export,
      "queries made the export of #{total} facts differ, seed #{seed}"
    )
  end

  def test_imports_export_that_carries_index
    seed = Random.new_seed
    rnd = Random.new(seed)
    origin = Factbase.new
    total = rnd.rand(1..100)
    total.times { |i| origin.insert.id = i }
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.import(Marshal.dump({ maps: origin.export, idx: { [rnd.rand, 'id'] => [] } }))
    assert_equal(total, fb.query('(exists id)').each.to_a.size, "facts of export with index were lost, seed #{seed}")
  end

  def test_insert_allows_incremental_query
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    f1 = fb.insert
    f1.foo = 42
    f1.id = 1
    assert_equal(1, fb.query('(eq foo 42)').each.to_a.size, 'Should find first fact with foo=42')
    f2 = fb.insert
    f2.foo = 42
    f2.id = 2
    assert_equal(2, fb.query('(eq foo 42)').each.to_a.size, 'Should find both facts after incremental update')
    f3 = fb.insert
    f3.foo = 99
    f3.id = 3
    assert_equal(2, fb.query('(eq foo 42)').each.to_a.size, 'Should still find two facts with foo=42')
    assert_equal(1, fb.query('(eq foo 99)').each.to_a.size, 'Should find one fact with foo=99')
  end

  def test_property_modification_clears_index
    idx = {}
    fb = Factbase::IndexedFactbase.new(Factbase.new, idx)
    fb.insert.foo = 42
    fb.query('(eq foo $val)').each(fb, { val: 42 }).to_a
    refute_empty(idx, 'Index should be populated after abstract query (with variable)')
    fb.query('(eq foo $val)').each(fb, { val: 42 }) { |f| f.bar = 13 }
    assert_empty(idx, 'Index should be cleared after modifying existing fact via abstract query')
  end

  def test_import_backward_compatibility
    fb1 = Factbase.new
    fb1.insert.foo = 42
    fb1.insert.bar = 13
    fb2 = Factbase::IndexedFactbase.new(Factbase.new)
    fb2.import(fb1.export)
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
    assert_operator(idx.size, :<, 10, 'Index must not accumulate stale entries across transactions')
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

  def test_term_absent_keeps_duplicates
    fb = Factbase.new
    fb.insert.cost = 10
    fb.insert.cost = 10
    assert_equal(2, fb.query('(absent scope)').each.to_a.size)
  end

  def test_indexed_term_absent_keeps_duplicates
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.cost = 10
    fb.insert.cost = 10
    assert_equal(2, fb.query('(absent scope)').each.to_a.size)
  end

  def test_indexed_term_absent_keeps_duplicates_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.txn do |fbt|
      fbt.insert.cost = 10
      fbt.insert.cost = 10
      assert_equal(2, fbt.query('(absent scope)').each.to_a.size)
    end
    assert_equal(2, fb.query('(absent scope)').each.to_a.size)
  end

  def test_term_exists_keeps_duplicates
    fb = Factbase.new
    fb.insert.scope = 1
    fb.insert.scope = 1
    assert_equal(2, fb.query('(exists scope)').each.to_a.size)
  end

  def test_indexed_term_exists_keeps_duplicates
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.scope = 1
    fb.insert.scope = 1
    assert_equal(2, fb.query('(exists scope)').each.to_a.size)
  end

  def test_indexed_term_exists_keeps_duplicates_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.txn do |fbt|
      fbt.insert.scope = 1
      fbt.insert.scope = 1
      assert_equal(2, fbt.query('(exists scope)').each.to_a.size)
    end
    assert_equal(2, fb.query('(exists scope)').each.to_a.size)
  end

  def test_term_not_keeps_duplicates
    fb = Factbase.new
    fb.insert.scope = 10
    fb.insert.scope = 10
    assert_equal(2, fb.query('(not (eq scope 20))').each.to_a.size)
  end

  def test_indexed_term_not_keeps_duplicates
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.scope = 10
    fb.insert.scope = 10
    assert_equal(2, fb.query('(not (eq scope 20))').each.to_a.size)
  end

  def test_indexed_term_not_keeps_duplicates_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.txn do |fbt|
      fbt.insert.scope = 10
      fbt.insert.scope = 10
      assert_equal(2, fbt.query('(not (eq scope 20))').each.to_a.size)
    end
    assert_equal(2, fb.query('(not (eq scope 20))').each.to_a.size)
  end

  def test_term_eq_keeps_duplicates
    fb = Factbase.new
    fb.insert.scope = 1
    fb.insert.scope = 1
    assert_equal(2, fb.query('(eq scope 1)').each.to_a.size)
  end

  def test_indexed_term_eq_keeps_duplicates
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.scope = 1
    fb.insert.scope = 1
    assert_equal(2, fb.query('(eq scope 1)').each.to_a.size)
  end

  def test_indexed_term_eq_keeps_duplicates_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.txn do |fbt|
      fbt.insert.scope = 1
      fbt.insert.scope = 1
      assert_equal(2, fbt.query('(eq scope 1)').each.to_a.size)
    end
    assert_equal(2, fb.query('(eq scope 1)').each.to_a.size)
  end

  def test_term_gt_keeps_duplicates
    fb = Factbase.new
    fb.insert.scope = 20
    fb.insert.scope = 20
    assert_equal(2, fb.query('(gt scope 10)').each.to_a.size)
  end

  def test_indexed_term_gt_keeps_duplicates
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.scope = 20
    fb.insert.scope = 20
    assert_equal(2, fb.query('(gt scope 10)').each.to_a.size)
  end

  def test_indexed_term_gt_keeps_duplicates_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.txn do |fbt|
      fbt.insert.scope = 20
      fbt.insert.scope = 20
      assert_equal(2, fbt.query('(gt scope 10)').each.to_a.size)
    end
    assert_equal(2, fb.query('(gt scope 10)').each.to_a.size)
  end

  def test_indexed_term_and_keeps_duplicates
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.txn do |fbt|
      f = fb.insert
      f.cost = 10
      f.scope = 10
      f = fb.insert
      f.cost = 10
      f.scope = 10
      assert_equal(2, fbt.query('(and (eq scope 10) (eq cost 10))').each.to_a.size)
    end
    assert_equal(2, fb.query('(and (eq scope 10) (eq cost 10))').each.to_a.size)
  end

  def test_indexed_term_and_keeps_many_duplicates_facts
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    total = 130
    total.times do
      f = fb.insert
      f.cost = 'cost'
      f.scope = 'scope'
    end
    q = '(and (exists cost) (exists scope))'
    assert_equal(total, fb.query(q).each.to_a.size)
    fb.txn { |fbt| assert_equal(total, fbt.query(q).each.to_a.size) }
  end

  def test_term_one_keeps_duplicates
    fb = Factbase.new
    fb.insert.scope = 10
    fb.insert.scope = 10
    assert_equal(2, fb.query('(one scope)').each.to_a.size)
  end

  def test_indexed_term_one_keeps_duplicates
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.scope = 10
    fb.insert.scope = 10
    assert_equal(2, fb.query('(one scope)').each.to_a.size)
  end

  def test_indexed_term_one_keeps_duplicates_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.txn do |fbt|
      fbt.insert.scope = 10
      fbt.insert.scope = 10
      assert_equal(2, fbt.query('(one scope)').each.to_a.size)
    end
    assert_equal(2, fb.query('(one scope)').each.to_a.size)
  end

  def test_term_lt_keeps_duplicates
    fb = Factbase.new
    fb.insert.scope = 10
    fb.insert.scope = 10
    assert_equal(2, fb.query('(lt scope 20)').each.to_a.size)
  end

  def test_indexed_term_lt_keeps_duplicates
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.scope = 10
    fb.insert.scope = 10
    assert_equal(2, fb.query('(lt scope 20)').each.to_a.size)
  end

  def test_indexed_term_lt_keeps_duplicates_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.txn do |fbt|
      fbt.insert.scope = 10
      fbt.insert.scope = 10
      assert_equal(2, fbt.query('(lt scope 20)').each.to_a.size)
    end
    assert_equal(2, fb.query('(lt scope 20)').each.to_a.size)
  end

  def test_unique_and_context
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    (1..200).each do |i|
      f = fb.insert
      f.id = i
      f.foo = (i <= 50 ? 1 : 2)
      f.bar = 3
    end
    assert_equal([51], fb.query('(and (eq foo 2) (unique bar))').each.to_a.map(&:id))
  end
end
