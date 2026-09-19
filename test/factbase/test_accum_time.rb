# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/query'
require_relative '../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestAccumTime < Factbase::Test
  def test_yields_a_time_whole
    moment = Time.now
    Factbase::Query.new([{ 'time' => moment }], '(always)', Factbase.new).each do |f|
      assert_equal([moment], f['time'])
    end
  end
end
