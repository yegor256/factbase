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

  def test_cannot_pick_max_of_booleans
    seed = Random.new_seed
    maps = [{ 'ok' => true }, { 'ok' => false }].shuffle(random: Random.new(seed))
    assert_raises(ArgumentError, "max of booleans #{maps} was not refused, seed #{seed}") do
      Factbase::Best.new { |a, b| a > b }.evaluate(:ok, maps)
    end
  end

  def test_cannot_pick_min_of_booleans
    seed = Random.new_seed
    maps = [{ 'ok' => true }, { 'ok' => false }].shuffle(random: Random.new(seed))
    assert_raises(ArgumentError, "min of booleans #{maps} was not refused, seed #{seed}") do
      Factbase::Best.new { |a, b| a < b }.evaluate(:ok, maps)
    end
  end

  def test_cannot_pick_max_of_boolean_after_number
    seed = Random.new_seed
    rnd = Random.new(seed)
    maps = [{ 'v' => rnd.rand(-1000..1000) }, { 'v' => rnd.rand(2).zero? }]
    assert_raises(ArgumentError, "boolean after number in #{maps} was not refused, seed #{seed}") do
      Factbase::Best.new { |a, b| a > b }.evaluate(:v, maps)
    end
  end

  def test_cannot_pick_min_of_boolean_after_number
    seed = Random.new_seed
    rnd = Random.new(seed)
    maps = [{ 'v' => rnd.rand(-1000..1000) }, { 'v' => rnd.rand(2).zero? }]
    assert_raises(ArgumentError, "boolean after number in #{maps} was not refused, seed #{seed}") do
      Factbase::Best.new { |a, b| a < b }.evaluate(:v, maps)
    end
  end

  def test_cannot_pick_max_of_booleans_in_one_property
    seed = Random.new_seed
    maps = [{ 'ok' => [true, false].shuffle(random: Random.new(seed)) }]
    assert_raises(ArgumentError, "booleans of one property #{maps} were not refused, seed #{seed}") do
      Factbase::Best.new { |a, b| a > b }.evaluate(:ok, maps)
    end
  end
end
