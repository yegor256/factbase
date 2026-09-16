# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'

# Test of 'to_integer' over a string with a leading zero.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToIntegerDecimal < Factbase::Test
  def test_leading_zero_is_not_octal
    fb = Factbase.new
    fb.insert.s = '010'
    assert_equal([10], fb.query('(as r (to_integer s))').each.to_a.first['r'])
  end

  def test_hexadecimal_prefix_is_refused
    fb = Factbase.new
    fb.insert.h = '0x1f'
    assert_raises(StandardError) do
      fb.query('(as r (to_integer h))').each.to_a
    end
  end
end
