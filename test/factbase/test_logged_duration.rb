# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/logged'
require_relative '../test__helper'

class TestLoggedDuration < Factbase::Test
  def test_reports_the_time_a_query_really_took
    log = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, log)
    fb.insert.foo = 1
    fb.query('(exists foo)').each { sleep(0.3) }
    refute_match(
      /by \(exists foo\) in \d+μs/, log.to_s,
      'a query that slept for 300ms cannot be reported in microseconds'
    )
  end
end
