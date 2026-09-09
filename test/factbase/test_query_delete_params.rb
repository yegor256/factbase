# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestQueryDeleteParams < Factbase::Test
  def test_deletes_by_a_parameter
    fb = Factbase.new
    fb.insert.foo = 1
    fb.insert.foo = 2
    assert_equal(1, fb.query('(eq foo $bar)').delete!(fb, { bar: 2 }))
    assert_equal(1, fb.size)
  end
end
