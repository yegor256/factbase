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
    assert_equal(1, fb.query('(eq foo 42)').each.to_a.size)
  end

  def test_finds_by_eq_with_array
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    f = fb.insert
    f.foo = 33
    f.foo = 42
    f.foo = 1
    assert_equal(1, fb.query('(eq foo 42)').each.to_a.size)
  end

  def test_finds_by_eq_with_agg
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.foo = 33
    fb.insert
    assert_equal(1, fb.query('(eq foo (agg (exists foo) (max foo)))').each.to_a.size)
  end

  def test_finds_max_value
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.foo = 33
    fb.insert
    assert_equal(42, fb.query('(agg (exists foo) (max foo))').one)
  end

  def test_finds_by_eq_with_formula
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert
    assert_equal(1, fb.query('(eq foo (plus 40 2))').each.to_a.size)
  end

  def test_finds_by_eq_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert
    fb.txn { |fbt| assert_equal(1, fbt.query('(eq foo 42)').each.to_a.size) }
  end

  def test_finds_with_conjunction
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.bar = 33
    assert_equal(2, fb.query('(or (exists foo) (exists bar))').each.to_a.size)
  end

  def test_finds_with_disjunction
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.bar = 33
    f = fb.insert
    f.foo = 42
    f.bar = 33
    assert_equal(1, fb.query('(and (exists foo) (exists bar))').each.to_a.size)
  end

  def test_finds_with_inversion
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.bar = 33
    assert_equal(1, fb.query('(not (exists foo))').each.to_a.size)
  end

  def test_finds_with_disjunction_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.insert.bar = 33
    f = fb.insert
    f.foo = 42
    f.bar = 33
    fb.txn { |fbt| assert_equal(1, fbt.query('(and (exists foo) (exists bar))').each.to_a.size) }
  end

  def test_attaches_alias
    fb = Factbase::CachedFactbase.new(Factbase::IndexedFactbase.new(Factbase.new))
    total = 10
    total.times do |i|
      f = fb.insert
      f.foo = rand(0..10)
      f.bar = rand(0..10)
      f.xyz = i
    end
    assert_equal(total, fb.query('(as boom (agg (eq foo $bar) (min xyz)))').each.to_a.size)
  end

  def test_joins_too
    fb = Factbase::IndexedFactbase.new(Factbase::CachedFactbase.new(Factbase.new))
    total = 10
    total.times do |i|
      f = fb.insert
      f.who = i
    end
    total.times do |i|
      f = fb.insert
      f.friend = i
    end
    assert_equal(total, fb.query('(and (exists who) (join "f<=friend" (eq friend $who)))').each.to_a.size)
  end

  def test_deletes_too
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 1
    fb.query('(eq foo 1)').delete!
    assert_equal(0, fb.query('(always)').each.to_a.size)
  end
end
