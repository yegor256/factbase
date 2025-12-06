# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/sum'

# Test for unique term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestSum < Factbase::Test
  def test_sum_regular_values
    t = Factbase::Sum.new([:value])
    res = t.evaluate(fact, [{ 'value' => 10 }, { 'value' => 20 }, { 'value' => 30 }], Factbase.new)
    assert_equal(60, res)
  end

  def test_sum_with_absent_values
    t = Factbase::Sum.new([:absent])
    res = t.evaluate(fact, [{ 'value' => 40 }, {}, { 'value' => 50 }], Factbase.new)
    assert_equal(0, res)
  end
end
