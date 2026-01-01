# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'threads'
require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/sync/sync_factbase'

# Sync factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSyncFactbase < Factbase::Test
  def test_queries_and_inserts
    fb = Factbase::SyncFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.query('(exists foo)').each do
      fb.insert
    end
  end

  def test_insert_threadsafe
    fb = Factbase::SyncFactbase.new(Factbase.new)
    Threads.new(10).assert do
      sleep(rand(0.01..0.20))
      fb.insert.then do |f|
        f.foo = 42
      end
    end
    assert_equal(10, fb.query('(exists foo)').each.to_a.size)
  end

  def test_nested_query_each_and_insert_threadsafe
    fb = Factbase::SyncFactbase.new(Factbase.new)
    fb.insert.baz = 43
    count = 0
    Threads.new(10).assert do
      fb.insert.bar = 42
      sleep(rand(0.01..0.10))
      fb.txn do |fbt|
        fbt.query('(exists baz)').each do |_f|
          sleep(rand(0.01..0.10))
          count += 1
          fbt.insert.foo = 42
        end
      end
    end
    assert_equal(1, fb.query('(exists baz)').each.to_a.size)
    assert_equal(10, fb.query('(exists foo)').each.to_a.size)
    assert_equal(10, fb.query('(exists bar)').each.to_a.size)
    assert_equal(10, count)
  end

  def test_change_property_value_in_txn_threadsafe
    fb = Factbase::SyncFactbase.new(Factbase.new)
    fb.insert.baz = 42
    t = 100
    Threads.new(t).assert do
      fb.insert.bar = 42
      sleep(rand(0.001..0.01))
      fb.txn do |fbt|
        fbt.query('(exists baz)').each do |f|
          sleep(rand(0.001..0.01))
          f.foo = 42
          fbt.insert.foo = 42
        end
      end
    end
    assert_equal(
      t + 1, fb.query('(exists foo)').each.to_a.size,
      'Number of facts with the foo property, must be equal to the number of threads that insert a new fact ' \
      'with the foo property + one modifying fact with baz property'
    )
    assert_equal(t, fb.query('(exists bar)').each.to_a.size)
    fb.query('(exists baz)').each.to_a.then do |fs|
      assert_equal(1, fs.size)
      assert_equal(t, fs.first['foo'].size)
    end
  end
end
