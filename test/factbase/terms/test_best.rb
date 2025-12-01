# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/best'

# Test for the 'best' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestBest < Factbase::Test
  def test_best_always_left
    t = Factbase::Best.new { |a, _b| a }
    best = t.evaluate(:age, [{ 'age' => [4, 3, 2] }, { 'age' => 25 }, { 'age' => 20 }])
    assert_equal(20, best)
  end

  def test_best_always_right
    t = Factbase::Best.new { |_a, b| b }
    best = t.evaluate(:age, [{ 'age' => [4, 3, 2] }, { 'age' => 25 }, { 'age' => 20 }])
    assert_equal(20, best)
  end

  def test_best_min
    t = Factbase::Best.new { |a, b| a < b }
    min = t.evaluate(:age, [{ 'age' => [4, 3, 2] }, { 'age' => 25 }, { 'age' => 20 }])
    assert_equal(2, min)
  end

  def test_best_max
    t = Factbase::Best.new { |a, b| a > b }
    max = t.evaluate(:age, [{ 'age' => [4, 3, 2] }, { 'age' => 25 }, { 'age' => 20 }])
    assert_equal(25, max)
  end
end
