# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'monitor'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/sync/sync_factbase'
require_relative '../../../lib/factbase/sync/sync_query'
require_relative '../../test__helper'

# A method of Factbase::SyncFactbase or Factbase::SyncQuery that does not take
# the monitor runs in the middle of another thread's transaction.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSyncMonitor < Factbase::Test
  def test_reads_wait_for_the_monitor
    monitor = Monitor.new
    fb = Factbase::SyncFactbase.new(Factbase.new, monitor)
    fb.insert.x = 1
    _assert_waits(monitor, 'Each') { fb.each(&:itself) }
    assert_equal(1, _assert_waits(monitor, 'Size') { fb.size })
    assert_equal(1, _assert_waits(monitor, 'QueryOne') { fb.query('(count)').one })
    _assert_waits(monitor, 'Export') { fb.export }
    _assert_waits(monitor, 'QueryDelete') { fb.query('(exists y)').delete! }
    assert_equal(1, fb.each(&:itself))
    assert_equal(1, Factbase.new.tap { |p| p.import(fb.export) }.size, 'The export was never read under the monitor')
  end

  def test_writes_wait_for_the_monitor
    monitor = Monitor.new
    fb = Factbase::SyncFactbase.new(Factbase.new, monitor)
    _assert_waits(monitor, 'Insert') { fb.insert.y = 1 }
    src = Factbase.new
    src.insert.z = 1
    _assert_waits(monitor, 'Import') { fb.import(src.export) }
    assert_equal(2, fb.size, 'Neither the insert nor the import changed the factbase')
  end

  def test_txn_waits_for_the_monitor
    monitor = Monitor.new
    fb = Factbase::SyncFactbase.new(Factbase.new, monitor)
    _assert_waits(monitor, 'Txn') { fb.txn { |_tx| :done } }
  end

  private

  # Assert that the given call stays blocked while the monitor is held, then
  # runs to the end once it is released.
  # @param [Monitor] monitor The monitor to hold
  # @param [String] name The name of the method being checked
  # @return [Object] What the call returned after the monitor was released
  def _assert_waits(monitor, name, &op)
    job = nil
    monitor.synchronize do
      job = Thread.new(&op)
      sleep(0.05)
      assert_predicate(job, :alive?, "The #{name} method did not wait for the monitor")
    end
    job.join(1)
    refute_predicate(job, :alive?, "The #{name} method never ran after the monitor was released")
    job.value
  end
end
