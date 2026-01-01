# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/terms/min'

# Test for the 'min' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestMin < Factbase::Test
  def test_not_enough_args
    term = Factbase::Min.new([])
    e =
      assert_raises(RuntimeError) do
        term.evaluate(nil, [], nil)
      end
    assert_includes(e.message, "Too few (0) operands for 'min' (1 expected)")
  end

  def test_too_many_args
    term = Factbase::Min.new([1, 2])
    e =
      assert_raises(RuntimeError) do
        term.evaluate(nil, [], nil)
      end
    assert_includes(e.message, "Too many (2) operands for 'min' (1 expected)")
  end

  def test_min_success
    term = Factbase::Min.new([:weight])
    result = term.evaluate(nil, [{ 'weight' => 60 }, { 'weight' => 25 }, { 'weight' => 42 }], nil)
    assert_equal(25, result)
  end
end
