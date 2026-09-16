# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../test__helper'

# Test of boolean terms over a multi-valued property.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestBooleanMulti < Factbase::Test
  def test_or_finds_a_true_that_is_not_first
    fb = Factbase.new
    f = fb.insert
    f.flag = false
    f.flag = true
    assert_equal(1, fb.query('(or flag)').each.to_a.size)
  end

  def test_and_wants_all_values_to_be_true
    fb = Factbase.new
    f = fb.insert
    f.flag = false
    f.flag = true
    assert_equal(0, fb.query('(and flag)').each.to_a.size)
  end
end
