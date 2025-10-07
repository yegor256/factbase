# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/impatient'
require_relative '../../../lib/factbase/sync/sync_factbase'

# Sync factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestSyncFactbase < Factbase::Test
  def test_queries_and_inserts
    fb = Factbase::SyncFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.query('(exists foo)').each do
      fb.insert
    end
  end

  def test_lock_unlock_mutex
    fb = Factbase.new
    fb = Class.new(Factbase::SyncFactbase) do
      def insert
        try_lock do
          sleep 0.5
          @origin.insert
        end
      end
    end.new(fb)
    ts = []
    ts << Thread.new do
      fb.insert.foo = 42
    end
    ts << Thread.new do
      sleep 0.1
      assert_equal(1, fb.query('(exists foo)').each.to_a.size)
    end
    ts.map(&:join)
  end

  def test_nested_lock_in_query_each_and_insert
    fb = Factbase::SyncFactbase.new(Factbase.new)
    fb.insert.baz = 43
    ts = []
    ts << Thread.new do
      fb.txn do |fbt|
        fbt.query('(exists baz)').each do |f|
          f.foo = 42
          fbt.insert.foo = 42
          sleep 0.07
        end
      end
    end
    ts << Thread.new do
      sleep 0.03
      assert_equal(2, fb.query('(exists foo)').each.to_a.size)
      assert_equal(1, fb.query('(exists baz)').each.to_a.size)
    end
    ts.map(&:join)
  end
end
