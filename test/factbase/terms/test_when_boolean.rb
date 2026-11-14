# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../test__helper'

# Test for the condition of the 'when' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestWhenBoolean < Factbase::Test
  def test_refuses_a_number_as_condition
    fb = Factbase.new
    fb.insert.z = 0
    assert_raises(StandardError, 'a number is taken as the condition of when') do
      fb.query('(when (at 0 z) (never))').each.to_a
    end
  end

  def test_still_takes_a_boolean_condition
    fb = Factbase.new
    fb.insert.z = 0
    assert_empty(fb.query('(when (always) (never))').each.to_a)
  end
end
