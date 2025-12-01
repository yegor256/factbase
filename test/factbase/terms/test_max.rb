# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/terms/max'

# Test for the 'max' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestMax < Factbase::Test
  def test_not_enough_args
    term = Factbase::Max.new([])
    e =
      assert_raises(RuntimeError) do
        term.evaluate(nil, [], nil)
      end
    assert_includes(e.message, "Too few (0) operands for 'max' (1 expected)")
  end

  def test_too_many_args
    term = Factbase::Max.new([1, 2])
    e =
      assert_raises(RuntimeError) do
        term.evaluate(nil, [], nil)
      end
    assert_includes(e.message, "Too many (2) operands for 'max' (1 expected)")
  end

  def test_max
    term = Factbase::Max.new([:height])
    result = term.evaluate(nil, [{ 'height' => 60 }, { 'height' => 25 }, { 'height' => 42 }], nil)
    assert_equal(60, result)
  end
end
