# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/nth'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for unique term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestNth < Factbase::Test
  def test_nth
    assert_equal(
      %w[2 3],
      Factbase::Nth.new([1, :number]).evaluate(
        fact,
        [{ 'number' => '1' }, { 'number' => %w[2 3] }, { 'number' => '4' }], Factbase.new
      )
    )
  end

  def test_nth_out_of_bounds
    assert_nil(
      Factbase::Nth.new([5, :letter]).evaluate(
        fact,
        [{ 'letter' => 'a' }, { 'letter' => 'b' }, { 'letter' => 'c' }], Factbase.new
      )
    )
  end
end
