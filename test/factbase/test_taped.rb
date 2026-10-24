# frozen_string_literal: true

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/taped'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTaped < Factbase::Test
  def test_distinguishes_nil_pattern_from_no_pattern
    values = Factbase::Taped::TapedArray.new([1], 1, [])
    refute(values.any?(nil))
    assert_predicate(values, :any?)
    assert(values.any?(Integer))
    refute(values.any? { |value| value > 1 })
    assert(Factbase::Taped::TapedArray.new([false], 1, []).any?(false))
  end

  def test_keeps_nil_pattern_results_after_transaction_copy
    base = Factbase.new
    base.insert.x = 1
    refute(base.each.first['x'].any?(nil))
    base.txn do |tx|
      refute(tx.each.first['x'].any?(nil))
      tx.query('(always)').each { |fact| fact.trigger = 1 }
      refute(tx.each.first['x'].any?(nil))
      assert_predicate(tx.each.first['x'], :any?)
    end
    refute(base.each.first['x'].any?(nil))
  end

  def test_tracks_insertion
    t = Factbase::Taped.new([])
    t << {}
    assert_equal(1, t.inserted.size)
  end

  def test_checks_for_emptiness
    refute_empty(Factbase::Taped.new([{ foo: 'yes' }]))
  end

  def test_joins_with_non_empty
    t = Factbase::Taped.new([{ foo: 'yes' }])
    t &= [{ bar: 'no' }]
    assert_equal(0, t.size)
  end

  def test_joins_with_empty
    t = Factbase::Taped.new([{ foo: 'yes' }])
    t &= []
    assert_equal(0, t.size)
  end

  def test_disjoins_with_empty
    t = Factbase::Taped.new([{ bar: 'oops' }])
    t |= []
    assert_equal(1, t.size)
  end

  def test_disjoins_with_non_empty
    t = Factbase::Taped.new([{ bar: 'oops' }])
    t |= [{ bar: 'no' }]
    assert_equal(2, t.size)
  end

  def test_tracks_deletion
    t = Factbase::Taped.new([{ x: 1 }, { x: 2 }])
    t.delete_if { |m| m[:x] == 1 }
    assert_equal(1, t.deleted.size)
  end

  def test_tracks_addition
    h = { f: 5 }
    t = Factbase::Taped.new([h])
    t.each do |m|
      m[:bar] = 66
    end
    assert_equal(1, t.added.size)
    assert_equal(h.object_id, t.added.first)
  end

  def test_tracks_addition_uniquely
    t = Factbase::Taped.new([{ f: 5 }])
    t.each do |m|
      m[:bar] = 66
      m[:foo] = 77
    end
    assert_equal(1, t.added.size)
  end

  def test_tracks_factbase
    t = Factbase::Taped.new([])
    fb = Factbase.new(t)
    fb.insert
    fb.query('(always)').each do |f|
      f.foo = 42
      f.foo = 5
    end
    fb.query('(always)').delete!
    assert_equal(1, t.inserted.size)
    assert_equal(1, t.added.size)
    assert_equal(1, t.deleted.size)
  end

  def test_gives_a_copy_from_to_a_of_an_array
    values = [20]
    Factbase::Taped::TapedArray.new(values, 1, []).to_a << 30
    assert_equal([20], values)
  end

  def test_sorts_hash_without_block
    seed = Random.new_seed
    rnd = Random.new(seed)
    names = Array.new(rnd.rand(2..8)) { |i| "p#{i}#{[*'a'..'z'].sample(rnd.rand(1..8), random: rnd).join}" }
    map = names.shuffle(random: rnd).to_h { |n| [n, [rnd.rand(1..1000)]] }
    assert_equal(
      map.sort, Factbase::Taped::TapedHash.new(map, []).sort,
      "taped hash of #{names.inspect} was not sorted by its keys, seed #{seed}"
    )
  end

  def test_answers_hash_calls_without_block_like_the_hash
    map = { 'a' => [1], 'b' => [2] }
    h = Factbase::Taped::TapedHash.new(map, [])
    assert_equal(2, h.count)
    assert_predicate(h, :any?)
    assert_equal(map, h.to_h)
    assert_equal(['a', [1]], h.min)
    assert_equal(map.uniq, h.uniq)
  end

  def test_answers_hash_calls_with_block_like_the_hash
    h = Factbase::Taped::TapedHash.new({ 'a' => [1], 'b' => [2] }, [])
    assert_equal(1, h.count { |_, v| v == [2] })
    assert_equal(['b', [2]], h.find { |k, _| k == 'b' })
    assert_equal({ 'a' => 1, 'b' => 2 }, h.to_h { |k, v| [k, v[0]] })
  end

  def test_answers_count_of_a_fact_inside_txn_after_a_write
    fb = Factbase.new
    f = fb.insert
    f.a = 1
    f.b = 2
    fb.insert.c = 3
    fb.txn do |t|
      t.query('(exists c)').each { |x| x.d = 4 }
      h = t.each.first
      assert_equal(2, h.count)
      assert_equal({ 'a' => [1], 'b' => [2] }, h.to_h)
    end
  end
end
