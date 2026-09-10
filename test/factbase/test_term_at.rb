# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTermAt < Factbase::Test
  def test_refuses_a_negative_position
    fb = Factbase.new
    f = fb.insert
    f.foo = 1
    f.foo = 2
    e =
      assert_raises(StandardError) do
        fb.query('(eq 2 (at -1 foo))').each.to_a
      end
    assert_includes(e.message, 'A non-negative position is expected, but -1 provided', e.message)
  end
end
