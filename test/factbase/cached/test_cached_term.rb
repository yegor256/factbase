# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/cached/cached_factbase'
require_relative '../../test__helper'

# Test for CachedTerm mixing.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestCachedTerm < Factbase::Test
  def test_caches_static_terms
    cache = {}
    fb = Factbase::CachedFactbase.new(Factbase.new, cache)
    fb.insert.foo = 42
    fb.query('(always)').each.to_a
    refute_nil(
      cache.keys.find do |k|
        k.is_a?(Array) && k.last.include?('always')
      end, "Expected a cached static term key in #{cache.keys}"
    )
  end

  def test_does_not_cache_head
    cache = {}
    fb = Factbase::CachedFactbase.new(Factbase.new, cache)
    fb.insert.foo = 42
    fb.query('(head 1 (always))').each.to_a
    head_key = cache.keys.find { |k| k.is_a?(Array) && k.last.include?('(head') }
    assert_nil(head_key, "Head term should not be cached, but found: #{head_key}")
  end

  def test_does_not_cache_unique
    cache = {}
    fb = Factbase::CachedFactbase.new(Factbase.new, cache)
    fb.insert.foo = 42
    fb.insert.foo = 99
    fb.query('(unique foo)').each.to_a
    assert_empty(cache.keys.grep(Array))
  end

  def test_keeps_nil_result_of_aggregate_over_no_facts
    seed = Random.new_seed
    origin = Factbase.new
    term = Factbase::CachedFactbase.new(origin, {}).to_term('(agg (exists hello) (min foo))')
    maps = []
    term.evaluate(fact({}), maps, origin)
    maps << { 'hello' => ["привет #{seed}"], 'foo' => [Random.new(seed).rand(1_000_000)] }
    assert_nil(
      term.evaluate(fact({}), maps, origin),
      "nil result of aggregate over no facts is evaluated again instead of being cached, seed #{seed}"
    )
  end

  def test_keeps_nil_result_of_aggregate_over_facts_without_property
    seed = Random.new_seed
    origin = Factbase.new
    term = Factbase::CachedFactbase.new(origin, {}).to_term('(agg (exists hello) (min foo))')
    maps = [{ 'hello' => ["здравствуй #{seed}"] }, { 'hello' => [''] }]
    term.evaluate(fact({}), maps, origin)
    maps.first['foo'] = [Random.new(seed).rand(1_000_000)]
    assert_nil(
      term.evaluate(fact({}), maps, origin),
      "nil result of aggregate over facts without property is evaluated again, seed #{seed}"
    )
  end

  def test_drops_nil_result_of_aggregate_after_insert
    seed = Random.new_seed
    value = "ключ #{Random.new(seed).rand(1_000_000)}"
    fb = Factbase::CachedFactbase.new(Factbase.new, {})
    fb.insert.bar = value
    fb.query('(eq bar (agg (exists foo) (min foo)))').each.to_a
    fb.insert.foo = value
    assert_equal(
      1, fb.query('(eq bar (agg (exists foo) (min foo)))').each.to_a.size,
      "cached nil result of aggregate survives an insert, seed #{seed}"
    )
  end

  def test_drops_nil_result_of_aggregate_after_property_change
    seed = Random.new_seed
    value = "замок #{Random.new(seed).rand(1_000_000)}"
    fb = Factbase::CachedFactbase.new(Factbase.new, {})
    fb.insert.bar = value
    fb.query('(eq bar (agg (exists bar) (min foo)))').each.to_a
    fb.query('(always)').each.first.foo = value
    assert_equal(
      1, fb.query('(eq bar (agg (exists bar) (min foo)))').each.to_a.size,
      "cached nil result of aggregate survives a property change, seed #{seed}"
    )
  end
end
