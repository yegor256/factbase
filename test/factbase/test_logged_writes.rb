# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/logged'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestLoggedWrites < Factbase::Test
  def test_logs_a_write_through_a_query
    log = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, log)
    fb.insert.foo = 1
    fb.query('(exists foo)').each { |f| f.bar = 7 }
    assert_includes(log.to_s, "Set 'bar' to 7")
  end
end
