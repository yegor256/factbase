# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/best'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for the 'best' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestBest < Factbase::Test
  def test_best_always_left
    assert_equal(
      20,
      Factbase::Best.new do |a, _b|
        a
      end.evaluate(:age, [{ 'age' => [4, 3, 2] }, { 'age' => 25 }, { 'age' => 20 }])
    )
  end

  def test_best_always_right
    assert_equal(
      20,
      Factbase::Best.new do |_a, b|
        b
      end.evaluate(:age, [{ 'age' => [4, 3, 2] }, { 'age' => 25 }, { 'age' => 20 }])
    )
  end

  def test_best_min
    assert_equal(
      2,
      Factbase::Best.new do |a, b|
        a < b
      end.evaluate(:age, [{ 'age' => [4, 3, 2] }, { 'age' => 25 }, { 'age' => 20 }])
    )
  end

  def test_best_max
    assert_equal(
      25,
      Factbase::Best.new do |a, b|
        a > b
      end.evaluate(:age, [{ 'age' => [4, 3, 2] }, { 'age' => 25 }, { 'age' => 20 }])
    )
  end
end
