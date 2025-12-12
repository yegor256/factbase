# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../../lib/factbase/sync/sync_factbase'
require_relative '../../../lib/factbase/cached/cached_factbase'

# Tests for incremental indexing bugs.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestIncrementalIndexing < Factbase::Test
  def test_query_correct_after_adding_property
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    f = fb.insert
    f.foo = 42
    assert_equal(1, fb.query('(eq foo 42)').each.to_a.size)
    assert_empty(fb.query('(exists bar)').each.to_a)
    fb.query('(eq foo 42)').each { |fact| fact.bar = 99 }
    assert_equal(1, fb.query('(exists bar)').each.to_a.size)
    assert_equal(1, fb.query('(eq bar 99)').each.to_a.size)
  end

  def test_delete_clears_index
    idx = {}
    fb = Factbase::IndexedFactbase.new(Factbase.new, idx)
    fb.insert.foo = 42
    fb.insert.foo = 43
    fb.query('(eq foo 42)').each.to_a
    refute_empty(idx)
    fb.query('(eq foo 43)').delete!
    assert_empty(idx)
    assert_empty(fb.query('(eq foo 43)').each.to_a)
  end

  def test_transaction_clears_index
    idx = {}
    fb = Factbase::IndexedFactbase.new(Factbase.new, idx)
    fb.insert.foo = 42
    fb.query('(eq foo 42)').each.to_a
    refute_empty(idx)
    fb.txn do |fbt|
      fbt.insert.bar = 1
      raise Factbase::Rollback
    end
    assert_empty(idx)
  end

  def test_fresh_fact_does_not_clear_index
    idx = {}
    fb = Factbase::IndexedFactbase.new(Factbase.new, idx)
    fb.insert.foo = 42
    fb.query('(eq foo 42)').each.to_a
    refute_empty(idx)
    f = fb.insert
    f.bar = 1
    f.bar = 2
    refute_empty(idx)
  end

  def test_incremental_indexing_on_insert
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    assert_equal(1, fb.query('(eq foo 42)').each.to_a.size)
    fb.insert.foo = 42
    assert_equal(2, fb.query('(eq foo 42)').each.to_a.size)
  end

  def test_delete_then_insert_same_count
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.value = 1
    fb.insert.value = 2
    fb.insert.value = 3
    assert_equal(1, fb.query('(eq value 2)').each.to_a.size)
    fb.query('(eq value 1)').delete!
    fb.insert.value = 4
    assert_empty(fb.query('(eq value 1)').each.to_a)
    assert_equal(1, fb.query('(eq value 4)').each.to_a.size)
  end

  def test_not_term_after_modification
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.foo = 99
    assert_equal(1, fb.query('(not (eq foo 42))').each.to_a.size)
    fb.query('(eq foo 42)').delete!
    assert_equal(1, fb.query('(not (eq foo 42))').each.to_a.size)
  end

  def test_gt_term_after_delete
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.value = 10
    fb.insert.value = 20
    fb.insert.value = 30
    assert_equal(2, fb.query('(gt value 15)').each.to_a.size)
    fb.query('(eq value 20)').delete!
    assert_equal(1, fb.query('(gt value 15)').each.to_a.size)
  end

  def test_and_term_incremental
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    f1 = fb.insert
    f1.foo = 42
    f1.bar = 1
    assert_equal(1, fb.query('(and (eq foo 42) (eq bar 1))').each.to_a.size)
    f2 = fb.insert
    f2.foo = 42
    f2.bar = 1
    assert_equal(2, fb.query('(and (eq foo 42) (eq bar 1))').each.to_a.size)
  end

  def test_cached_query_sees_fresh_fact
    fb = Factbase::CachedFactbase.new(Factbase::IndexedFactbase.new(Factbase.new))
    fb.query('(eq foo 1)').each.to_a # warm cache with empty result
    f1 = fb.insert
    f1.foo = 1
    assert_equal(1, fb.query('(eq foo 1)').each.to_a.size)
    f2 = fb.insert
    f2.foo = 1
    assert_equal(2, fb.query('(eq foo 1)').each.to_a.size)
  end

end
