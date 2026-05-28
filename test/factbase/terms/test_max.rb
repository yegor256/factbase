# frozen_string_literal: true

require_relative '../../../lib/factbase/terms/max'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for the 'max' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestMax < Factbase::Test
  def test_not_enough_args
    term = Factbase::Max.new([])
    assert_includes(
      assert_raises(StandardError) do
        term.evaluate(nil, [], nil)
      end.message, "Too few (0) operands for 'max' (1 expected)"
    )
  end

  def test_too_many_args
    term = Factbase::Max.new([1, 2])
    assert_includes(
      assert_raises(StandardError) do
        term.evaluate(nil, [], nil)
      end.message, "Too many (2) operands for 'max' (1 expected)"
    )
  end

  def test_max
    assert_equal(
      60,
      Factbase::Max.new([:height]).evaluate(
        nil, [{ 'height' => 60 }, { 'height' => 25 }, { 'height' => 42 }],
        nil
      )
    )
  end
end
