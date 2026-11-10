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
    _assert_waits(monitor, 'Size') { fb.size }
    _assert_waits(monitor, 'Export') { fb.export }
    _assert_waits(monitor, 'QueryOne') { fb.query('(exists x)').one }
    _assert_waits(monitor, 'QueryDelete') { fb.query('(exists y)').delete! }
    assert_equal(1, fb.each(&:itself))
  end

  def test_writes_wait_for_the_monitor
    monitor = Monitor.new
    fb = Factbase::SyncFactbase.new(Factbase.new, monitor)
    _assert_waits(monitor, 'Insert') { fb.insert }
    _assert_waits(monitor, 'Import') { fb.import(Factbase.new.export) }
  end

  private

  # Assert that the given call stays blocked while the monitor is held.
  # @param [Monitor] monitor The monitor to hold
  # @param [String] name The name of the method being checked
  def _assert_waits(monitor, name, &op)
    monitor.synchronize do
      t = Thread.new(&op)
      sleep(0.05)
      assert_predicate(t, :alive?, "The #{name} method did not wait for the monitor")
      t.kill
    end
  end
end
