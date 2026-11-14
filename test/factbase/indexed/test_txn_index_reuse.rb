# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTxnIndexReuse < Factbase::Test
  # Counts how many times the index feeds on this list of values, and keeps
  # counting after LazyTaped copies the fact in a transaction (`dup` shares it).
  class CountingArray < Array
    def initialize(values, counter)
      super(values)
      @counter = counter
    end

    def each(&)
      @counter[0] += 1
      super
    end
  end

  def test_read_inside_txn_does_not_touch_every_fact
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    10.times { |i| fb.insert.kind = i }
    fb.query('(eq kind 5)').each.to_a
    reads = 0
    fb.each do |m|
      m.define_singleton_method(:[]) do |k|
        reads += 1
        super(k)
      end
    end
    found = nil
    fb.txn do |fbt|
      found = fbt.query('(eq kind 5)').each.to_a
    end
    assert_equal(1, found.size)
    assert_equal(0, reads, 'A transactional read must reuse the index and not scan every fact')
  end

  def test_rolled_back_insert_does_not_poison_the_index
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.kind = 1
    fb.query('(eq kind 1)').each.to_a
    fb.txn do |fbt|
      fbt.insert.kind = 2
      assert_equal(1, fbt.query('(eq kind 2)').each.to_a.size)
      raise(Factbase::Rollback)
    end
    fb.insert.kind = 1
    assert_equal(0, fb.query('(eq kind 2)').each.to_a.size)
    assert_equal(2, fb.query('(eq kind 1)').each.to_a.size)
  end

  def test_insert_and_query_interleaved_in_txn_does_not_rescan
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    10.times { |i| fb.insert.kind = i }
    feeds = [0]
    fb.each { |m| m['kind'] = CountingArray.new(m['kind'], feeds) }
    fb.txn do |fbt|
      10.times do |i|
        fbt.insert.kind = i + 10
        fbt.query("(eq kind #{i})").each.to_a
      end
    end
    assert_equal(
      10, feeds[0],
      'Clearing the shared index once per transaction keeps indexing linear; ' \
      'clearing it on every insert re-feeds every fact inserted so far (quadratic)'
    )
  end

  def test_insert_only_txn_keeps_the_factbase_index_warm
    idx = {}
    fb = Factbase::IndexedFactbase.new(Factbase.new, idx)
    fb.insert.kind = 1
    fb.query('(eq kind 1)').each.to_a
    refute_empty(idx)
    fb.txn { |fbt| fbt.insert.kind = 2 }
    refute_empty(idx, 'An insert-only transaction must not empty the factbase index')
    assert_equal(1, fb.query('(eq kind 1)').each.to_a.size)
    assert_equal(1, fb.query('(eq kind 2)').each.to_a.size)
  end

  def test_scoped_index_does_not_answer_a_whole_factbase_query_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    4.times { fb.insert.kind = 1 }
    assert_equal(2, fb.query('(eq kind 1)', fb.to_enum(:each).to_a[0..1]).each.to_a.size)
    fb.txn do |fbt|
      assert_equal(4, fbt.query('(eq kind 1)').each.to_a.size)
    end
  end

  def test_rolled_back_update_keeps_the_factbase_index
    idx = {}
    fb = Factbase::IndexedFactbase.new(Factbase.new, idx)
    fb.insert.kind = 1
    fb.query('(eq kind 1)').each.to_a
    refute_empty(idx)
    fb.txn do |fbt|
      fbt.query('(eq kind 1)').each { |f| f.kind = 2 }
      raise(Factbase::Rollback)
    end
    refute_empty(idx)
    assert_equal(1, fb.query('(eq kind 1)').each.to_a.size)
  end

  def test_txn_query_after_insert_sees_every_fact
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.kind = 1
    fb.insert.kind = 1
    fb.txn do |fbt|
      fbt.insert.kind = 1
      assert_equal(3, fbt.query('(eq kind 1)').each.to_a.size)
    end
    assert_equal(3, fb.query('(eq kind 1)').each.to_a.size)
  end
end
