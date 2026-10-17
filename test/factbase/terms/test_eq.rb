# frozen_string_literal: true

require 'benchmark'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/eq'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
require_relative '../../test__helper'

# Tests for the 'eq' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestEq < Factbase::Test
  def test_compares_equal
    assert(Factbase::Eq.new([:number, 42]).evaluate(fact('number' => 42), [], Factbase.new))
  end

  def test_compares_not_equal
    refute(Factbase::Eq.new([:number, 42]).evaluate(fact('number' => 100), [], Factbase.new))
  end

  def test_compares_numbers_with_many_values
    fb = Factbase.new
    fb.insert.id = 42
    fb.insert.id = 100
    ids = (1..20).to_a
    assert_empty(fb.query('(eq id $ids)').each(fb, 'ids' => ids).to_a)
    ids << 42
    assert_equal(1, fb.query('(eq id $ids)').each(fb, 'ids' => ids).to_a.size)
  end

  def test_compares_integer_and_float_equality
    fb = Factbase.new
    fb.insert.id = 42.0
    assert_equal(1, fb.query('(eq id $ids)').each(fb, 'ids' => [1, 2, 3, 42, 5, 6, 7, 8, 9, 10]).to_a.size)
  end

  def test_compares_strings_with_many_values
    fb = Factbase.new
    fb.insert.tag = 'ruby'
    fb.insert.tag = 'python'
    assert_equal(
      1,
      fb.query('(eq tag $tags)').each(fb, 'tags' => %w[c java rust go elixir swift kotlin scala clojure ruby]).to_a.size
    )
  end

  def test_compares_times_with_many_values
    fb = Factbase.new
    now = Time.utc(2026, 10, 17, 12, 0, 0)
    fb.insert.when = Time.utc(2026, 10, 17, 12, 0, 0, 500_000)
    times = (1..10).map { |i| now - (i * 3600) }
    assert_empty(fb.query('(eq when $times)').each(fb, 'times' => times).to_a)
    times << now
    assert_equal(1, fb.query('(eq when $times)').each(fb, 'times' => times).to_a.size)
  end

  def test_compares_multi_values_on_left
    fb = Factbase.new
    f = fb.insert
    (1..10).each { |i| f.tags = i }
    assert_equal(1, fb.query('(eq tags 5)').each(fb).to_a.size)
  end

  def test_fast_execution_with_many_values
    fb = Factbase.new
    fb.insert.id = 2500
    assert_operator(
      Benchmark.realtime { assert_equal(1, fb.query('(eq id $ids)').each(fb, 'ids' => (1..2500).to_a).to_a.size) },
      :<,
      0.5
    )
  end
end
