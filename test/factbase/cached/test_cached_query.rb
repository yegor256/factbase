# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/cached/cached_factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../../lib/factbase/logged'
require_relative '../../../lib/factbase/sync/sync_factbase'
require_relative '../../test__helper'

# Query test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestCachedQuery < Factbase::Test
  def test_queries_many_times
    fb = Factbase::CachedFactbase.new(Factbase.new)
    total = 5
    total.times { fb.insert }
    total.times do
      assert_equal(5, fb.query('(always)').each.to_a.size)
    end
  end

  def test_negates_correctly
    fb = Factbase::CachedFactbase.new(Factbase.new)
    fb.insert.foo = 42
    3.times do
      assert_equal(1, fb.query('(always)').each.to_a.size)
      assert_equal(0, fb.query('(not (always))').each.to_a.size)
    end
  end

  def test_aggregates_too
    fb = Factbase::IndexedFactbase.new(Factbase::CachedFactbase.new(Factbase.new))
    10_000.times do |i|
      f = fb.insert
      f.foo = i
      f.hello = 1
    end
    3.times do
      assert_equal(1, fb.query('(eq foo (agg (exists hello) (min foo)))').each.to_a.size)
    end
  end

  def test_joins_too
    fb = Factbase::IndexedFactbase.new(Factbase::CachedFactbase.new(Factbase.new))
    total = 10
    total.times do |i|
      f = fb.insert
      f.foo = i
      f.hello = 1
    end
    3.times do
      assert_equal(total, fb.query('(join "bar<=foo" (eq foo (agg (exists hello) (min foo))))').each.to_a.size)
    end
  end

  def test_works_with_logging
    fb = Factbase::CachedFactbase.new(Factbase::Logged.new(Factbase.new, Loog::NULL))
    total = 10
    total.times do |i|
      f = fb.insert
      f.foo = i
      f.hello = 1
    end
    3.times do
      [
        '(exists foo)',
        '(and (gt foo -99) (exists hello))',
        '(and (lt hello 1000.44) (exists foo) (not (exists bar)))'
      ].each do |q|
        assert_equal(total, fb.query(q).each.to_a.size)
      end
    end
  end

  def test_caches_while_being_decorated
    fb = Factbase::SyncFactbase.new(Factbase::CachedFactbase.new(Factbase.new))
    10_000.times do |i|
      f = fb.insert
      f.foo = i
      f.hello = 1
    end
    3.times do
      assert_equal(1, fb.query('(eq foo (agg (exists hello) (min foo)))').each.to_a.size)
    end
  end

  def test_deletes_too
    fb = Factbase::CachedFactbase.new(Factbase.new)
    fb.insert.foo = 1
    fb.query('(eq foo 1)').delete!
    assert_equal(0, fb.query('(always)').each.to_a.size)
  end

  def test_yields_facts_of_the_param_given_to_each_call
    seed = Random.new_seed
    rnd = Random.new(seed)
    first = rnd.rand(1_000)
    second = first + rnd.rand(1..1_000)
    fb = Factbase::CachedFactbase.new(Factbase.new)
    [first, second].each { |v| fb.insert.value = v }
    query = fb.query('(eq value $wanted)')
    query.each(fb, wanted: [first]).to_a
    assert_equal(
      [[second]], query.each(fb, wanted: [second]).map { |f| f['value'] },
      "a second param cannot get the facts cached for the first one, seed #{seed}"
    )
  end

  def test_yields_facts_of_the_param_hidden_inside_an_aggregate
    seed = Random.new_seed
    rnd = Random.new(seed)
    first = rnd.rand(1_000)
    second = first + rnd.rand(1..1_000)
    fb = Factbase::CachedFactbase.new(Factbase.new)
    [first, second].each { |v| fb.insert.value = v }
    query = fb.query('(eq value (agg (eq value $wanted) (max value)))')
    query.each(fb, wanted: [first]).to_a
    assert_equal(
      [[second]], query.each(fb, wanted: [second]).map { |f| f['value'] },
      "a param inside an aggregate cannot get the facts cached for another one, seed #{seed}"
    )
  end

  def test_reads_one_value_of_the_param_given_to_each_call
    seed = Random.new_seed
    rnd = Random.new(seed)
    first = rnd.rand(1_000)
    second = first + rnd.rand(1..1_000)
    fb = Factbase::CachedFactbase.new(Factbase.new)
    [first, second].each { |v| fb.insert.value = v }
    query = fb.query('(agg (eq value $wanted) (first value))')
    query.one(fb, wanted: [first])
    assert_equal(
      [second], query.one(fb, wanted: [second]),
      "a second param cannot get the value cached for the first one, seed #{seed}"
    )
  end
end
