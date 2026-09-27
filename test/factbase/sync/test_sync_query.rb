# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/sync/sync_factbase'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'benchmark'
require_relative '../../test__helper'

# Query test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSyncQuery < Factbase::Test
  def test_does_not_hold_the_monitor_while_the_block_runs
    fb = Factbase::SyncFactbase.new(Factbase.new)
    3.times { |i| fb.insert.foo = i }
    Thread.new { fb.query('(always)').each { sleep(0.1) } }
    sleep(0.05)
    assert_operator(Benchmark.realtime { fb.insert.bar = 1 }, :<, 0.2)
  end

  def test_queries_many_times
    fb = Factbase::SyncFactbase.new(Factbase.new)
    total = 5
    total.times { fb.insert }
    total.times do
      assert_equal(5, fb.query('(always)').each.to_a.size)
    end
  end

  def test_deletes_too
    fb = Factbase::SyncFactbase.new(Factbase.new)
    fb.insert.foo = 1
    fb.query('(eq foo 1)').delete!
    assert_equal(0, fb.query('(always)').each.to_a.size)
  end
end
