# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'monitor'
require 'timeout'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/sync/sync_fact'
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

  def test_reads_a_property_with_the_name_of_a_private_method
    fact = Factbase::SyncFact.new(Factbase.new.insert, Monitor.new)
    fact.rand = 42
    assert_equal(42, fact.rand)
  end

  def test_prints_what_the_origin_prints
    origin = Factbase.new.insert
    origin.foo = 42
    assert_equal(origin.to_s, Factbase::SyncFact.new(origin, Monitor.new).to_s)
  end

  def test_waits_for_the_monitor_to_be_free
    monitor = Monitor.new
    fact = Factbase::SyncFact.new(Factbase.new.insert, monitor)
    ready = Queue.new
    writer = nil
    monitor.synchronize do
      writer =
        Thread.new do
          ready << true
          fact.foo = 42
        end
      Timeout.timeout(2) do
        ready.pop
        Thread.pass until writer.status == 'sleep' || !writer.alive?
      end
      assert_equal('sleep', writer.status, 'the writer must block on the held monitor')
    end
    assert(writer.join(2), 'the writer must finish when the monitor is released')
    assert_equal([42], fact['foo'])
  ensure
    writer&.kill
    writer&.join
  end
end
