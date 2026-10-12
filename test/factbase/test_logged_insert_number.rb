# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/logged'
require_relative '../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestLoggedInsertNumber < Factbase::Test
  def test_numbers_the_fact_that_was_inserted
    log = Loog::Buffer.new
    fb = Factbase::Logged.new(Factbase.new, log)
    fb.insert
    fb.insert
    assert_includes(log.to_s, 'fact #1')
    assert_includes(log.to_s, 'fact #2')
    refute_includes(log.to_s, 'fact #0')
  end
end
