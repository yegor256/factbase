# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_time'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'to_time' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToTime < Factbase::Test
  def test_to_time
    assert_equal('Time', Factbase::ToTime.new([%w[2023-01-01 hello]]).evaluate(fact, [], Factbase.new).class.to_s)
  end
end
