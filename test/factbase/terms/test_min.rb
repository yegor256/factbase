# frozen_string_literal: true

require_relative '../../../lib/factbase/terms/min'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for the 'min' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestMin < Factbase::Test
  def test_not_enough_args
    term = Factbase::Min.new([])
    assert_includes(
      assert_raises(StandardError) do
        term.evaluate(nil, [], nil)
      end.message, "Too few (0) operands for 'min' (1 expected)"
    )
  end

  def test_too_many_args
    term = Factbase::Min.new([1, 2])
    assert_includes(
      assert_raises(StandardError) do
        term.evaluate(nil, [], nil)
      end.message, "Too many (2) operands for 'min' (1 expected)"
    )
  end

  def test_min_success
    assert_equal(
      25,
      Factbase::Min.new([:weight]).evaluate(
        nil, [{ 'weight' => 60 }, { 'weight' => 25 }, { 'weight' => 42 }],
        nil
      )
    )
  end
end
