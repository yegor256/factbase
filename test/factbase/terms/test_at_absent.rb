# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../test__helper'

class TestAtAbsent < Factbase::Test
  def test_answers_nothing_for_an_absent_index
    fb = Factbase.new
    f = fb.insert
    f.foo = 42
    f.multi = 7
    assert_empty(
      fb.query('(eq foo (at absent_prop multi))').each.to_a,
      'an absent index must answer nothing, not raise'
    )
  end

  def test_refuses_a_fractional_position
    fb = Factbase.new
    f = fb.insert
    f.x = 10
    f.x = 20
    f.x = 30
    e = assert_raises(StandardError) { fb.query('(eq (at 1.9 x) 20)').each.to_a }
    assert_includes(e.message, 'An integer position is expected, but 1.9 provided', e.message)
  end
end
