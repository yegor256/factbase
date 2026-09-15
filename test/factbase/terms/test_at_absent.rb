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
end
