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
end
