# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/cached/cached_factbase'

# Query test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestCachedFactbase < Factbase::Test
  def test_inserts_and_queries
    fb = Factbase::CachedFactbase.new(Factbase.new)
    f = fb.insert
    f.foo_bar = 1
    f.bar = 'test'
    assert_equal(1, fb.query('(and (eq foo_bar 1) (eq bar "test"))').each.to_a.size)
  end

  def test_queries_after_update_in_txn
    origin = Factbase.new
    fb = Factbase::CachedFactbase.new(origin)
    fb.insert.foo = 42
    fb.txn do |fbt|
      fbt.query('(exists foo)').each do |f|
        f.bar = 33
      end
    end
    refute_empty(origin.query('(exists bar)').each.to_a)
    refute_empty(fb.query('(exists bar)').each.to_a)
  end

  def test_prints_fact_correctly
    fb = Factbase::CachedFactbase.new(Factbase.new)
    f1 = fb.insert
    f1.foo = 42
    assert_equal('[ foo: [42] ]', f1.to_s)
    f2 = fb.query('(always)').each.to_a.first
    assert_equal('[ foo: [42] ] + {}', f2.to_s)
  end
end
