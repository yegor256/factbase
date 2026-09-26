# frozen_string_literal: true

require 'monitor'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/sync/sync_fact'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Sync fact test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSyncFact < Factbase::Test
  def test_reads_and_writes_through_the_origin
    fb = Factbase.new
    fact = Factbase::SyncFact.new(fb.insert, Monitor.new)
    fact.foo = 42
    assert_equal([42], fact['foo'])
    assert_equal([42], fb.query('(exists foo)').each.to_a.first['foo'])
  end

  def test_prints_what_the_origin_prints
    origin = Factbase.new.insert
    origin.foo = 42
    assert_equal(origin.to_s, Factbase::SyncFact.new(origin, Monitor.new).to_s)
  end

  def test_waits_for_the_monitor_to_be_free
    monitor = Monitor.new
    fact = Factbase::SyncFact.new(Factbase.new.insert, monitor)
    done = Queue.new
    writer = nil
    monitor.synchronize do
      writer =
        Thread.new do
          fact.foo = 42
          done << :written
        end
      sleep(0.2)
      assert_empty(done, 'the write must not happen while another thread holds the monitor')
    end
    writer.join
    assert_equal([42], fact['foo'])
  end
end
