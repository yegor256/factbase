# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/nth'

# Test for unique term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestNth < Factbase::Test
  def test_nth
    t = Factbase::Nth.new([1, :number])
    res = t.evaluate(fact, [{ 'number' => '1' }, { 'number' => %w[2 3] }, { 'number' => '4' }], Factbase.new)
    assert_equal(%w[2 3], res)
  end

  def test_nth_out_of_bounds
    t = Factbase::Nth.new([5, :letter])
    res = t.evaluate(fact, [{ 'letter' => 'a' }, { 'letter' => 'b' }, { 'letter' => 'c' }], Factbase.new)
    assert_nil(res)
  end
end
