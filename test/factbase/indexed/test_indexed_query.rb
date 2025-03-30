# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/cached/cached_factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'

# Query test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestIndexedQuery < Factbase::Test
  def test_queries_and_updates_origin
    fb = Factbase.new
    fb.insert.foo = 42
    Factbase::IndexedQuery.new(fb.query('(exists foo)'), {}, fb).each do |f|
      f.bar = 33
    end
    refute_empty(fb.query('(exists bar)').each.to_a)
  end

  def test_queries_many_times
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    total = 5
    total.times { fb.insert }
    total.times do
      assert_equal(5, fb.query('(always)').each.to_a.size)
    end
  end

  def test_finds_by_eq
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert
    3.times do
      assert_equal(1, fb.query('(eq foo 42)').each.to_a.size)
    end
  end

  def test_fills_up_the_index
    idx = {}
    fb = Factbase::IndexedFactbase.new(Factbase.new, idx)
    fb.query('(eq x 1)').each.to_a
    assert_equal(1, idx.size)
    fb.insert
    assert_empty(idx)
  end

  def test_finds_by_eq_with_symbol
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    f = fb.insert
    f.num = 256
    f.num = 42
    fb.insert.num = 42
    fb.insert.num = 55
    fb.insert
    fb.insert
    3.times do
      assert_equal(1, fb.query('(eq 1 (agg (eq num $num) (count)))').each.to_a.size)
    end
  end

  def test_finds_by_eq_with_array
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    f = fb.insert
    f.foo = 33
    f.foo = 42
    f.foo = 1
    3.times do
      assert_equal(1, fb.query('(eq foo 42)').each.to_a.size)
    end
  end

  def test_finds_by_eq_with_agg
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.foo = 33
    fb.insert
    3.times do
      assert_equal(1, fb.query('(eq foo (agg (exists foo) (max foo)))').each.to_a.size)
    end
  end

  def test_finds_max_value
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.foo = 33
    fb.insert
    3.times do
      assert_equal(42, fb.query('(agg (exists foo) (max foo))').one)
    end
  end

  def test_finds_by_eq_with_formula
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert
    3.times do
      assert_equal(1, fb.query('(eq foo (plus 40 2))').each.to_a.size)
    end
  end

  def test_finds_by_eq_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert
    3.times do
      fb.txn { |fbt| assert_equal(1, fbt.query('(eq foo 42)').each.to_a.size) }
    end
  end

  def test_finds_with_conjunction
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.bar = 33
    3.times do
      assert_equal(2, fb.query('(or (exists foo) (exists bar))').each.to_a.size)
    end
  end

  def test_finds_with_disjunction
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.bar = 33
    f = fb.insert
    f.foo = 42
    f.bar = 33
    3.times do
      assert_equal(1, fb.query('(and (exists foo) (exists bar))').each.to_a.size)
    end
  end

  def test_finds_with_inversion
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.bar = 33
    3.times do
      assert_equal(1, fb.query('(not (exists foo))').each.to_a.size)
    end
  end

  def test_finds_with_disjunction_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.bar = 33
    f = fb.insert
    f.foo = 42
    f.bar = 33
    3.times do
      fb.txn { |fbt| assert_equal(1, fbt.query('(and (exists foo) (exists bar))').each.to_a.size) }
    end
  end

  def test_attaches_alias
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    total = 10
    total.times do |i|
      f = fb.insert
      f.foo = rand(0..10)
      f.bar = rand(0..10)
      f.xyz = i
    end
    3.times do
      assert_equal(total, fb.query('(as boom (agg (eq foo $bar) (min xyz)))').each.to_a.size)
    end
  end

  def test_joins_simple_one
    idx = {}
    fb = Factbase::IndexedFactbase.new(Factbase.new, idx)
    fb.insert.who = 4
    fb.insert.friend = 4
    assert_equal(1, fb.query('(and (exists who) (join "f<=friend" (eq friend $who)))').each.to_a.size)
    assert_equal(2, idx.size)
  end

  def test_joins_too
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    total = 10_000
    total.times do |i|
      f = fb.insert
      f.who = i
    end
    total.times do |i|
      f = fb.insert
      f.friend = i
    end
    3.times do
      assert_equal(total, fb.query('(and (exists who) (join "f<=friend" (eq friend $who)))').each.to_a.size)
    end
  end

  def test_deletes_too
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 1
    fb.query('(eq foo 1)').delete!
    assert_equal(0, fb.query('(always)').each.to_a.size)
  end
end
