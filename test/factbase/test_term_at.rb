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

  def test_refuses_several_positions
    fb = Factbase.new
    f = fb.insert
    f.idx = 0
    f.idx = 1
    f.foo = 2
    assert_includes(
      assert_raises(RuntimeError) do
        fb.query('(eq 2 (at idx foo))').each.to_a
      end.message, 'Too many values (2) at first position, one expected'
    )
  end
end
