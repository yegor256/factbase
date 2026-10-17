# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/sum'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for unique term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSum < Factbase::Test
  def test_sum_regular_values
    assert_equal(
      60,
      Factbase::Sum.new([:value]).evaluate(
        fact, [{ 'value' => 10 }, { 'value' => 20 }, { 'value' => 30 }],
        Factbase.new
      )
    )
  end

  def test_sum_with_absent_values
    assert_equal(
      0,
      Factbase::Sum.new([:absent]).evaluate(fact, [{ 'value' => 40 }, {}, { 'value' => 50 }], Factbase.new)
    )
  end

  def test_refuses_extra_operands
    assert_includes(
      assert_raises(ArgumentError) do
        Factbase::Sum.new(%i[a b]).evaluate(fact, [{ 'a' => 1, 'b' => 10 }], Factbase.new)
      end.message,
      "Too many (2) operands for 'sum' (1 expected)"
    )
  end

  def test_names_the_property_and_the_value
    fb = Factbase.new
    fb.insert.name = 'alice'
    assert_includes(
      assert_raises(StandardError) do
        fb.query('(gt (sum name) 0)').each.to_a
      end.message, "The value 'alice' of the 'name' property is not a number"
    )
  end

  def test_sum_when_middle_facts_lack_property_integers
    assert_equal(
      60,
      Factbase::Sum.new([:val]).evaluate(
        fact,
        [
          { 'val' => 10 },
          { 'other' => 99 },
          {},
          { 'val' => 20 },
          { 'extra' => 'info' },
          { 'val' => 30 }
        ],
        Factbase.new
      )
    )
  end

  def test_sum_when_first_middle_and_last_facts_lack_property_integers
    assert_equal(
      50,
      Factbase::Sum.new([:score]).evaluate(
        fact,
        [
          {},
          { 'score' => 15 },
          { 'note' => 'skip me' },
          {},
          { 'score' => 25 },
          { 'score' => 10 },
          {}
        ],
        Factbase.new
      )
    )
  end

  def test_sum_when_middle_facts_lack_property_floats
    assert_in_delta(
      7.0,
      Factbase::Sum.new([:price]).evaluate(
        fact,
        [
          { 'price' => 1.25 },
          { 'name' => 'apple' },
          {},
          { 'price' => 2.5 },
          { 'sku' => 123 },
          { 'price' => 3.25 }
        ],
        Factbase.new
      ),
      0.0001
    )
  end

  def test_sum_when_middle_facts_lack_property_mixed_numbers
    assert_in_delta(
      32.0,
      Factbase::Sum.new([:delta]).evaluate(
        fact,
        [
          { 'delta' => 10 },
          {},
          { 'delta' => 2.5 },
          { 'label' => 'tag' },
          { 'delta' => 15 },
          { 'delta' => 4.5 }
        ],
        Factbase.new
      ),
      0.0001
    )
  end

  def test_sum_when_middle_facts_lack_property_with_array_values
    assert_equal(
      80,
      Factbase::Sum.new([:points]).evaluate(
        fact,
        [
          { 'points' => [10, 5] },
          {},
          { 'comment' => 'no points' },
          { 'points' => [20, 15] },
          {},
          { 'points' => 30 }
        ],
        Factbase.new
      )
    )
  end

  def test_sum_query_when_middle_facts_lack_property
    fb = Factbase.new
    fb.insert.cost = 100
    fb.insert.title = 'middle fact without cost'
    fb.insert.cost = 250
    fb.insert.flag = true
    fb.insert.cost = 150
    assert_equal(5, fb.query('(eq (sum cost) 500)').each.to_a.size)
    assert_equal([100, 250, 150], fb.query('(and (exists cost) (eq (sum cost) 500))').each.to_a.map(&:cost))
  end

  def test_sum_agg_query_when_middle_facts_lack_property_floats
    fb = Factbase.new
    fb.insert.weight = 10.5
    fb.insert.desc = 'item without weight'
    fb.insert.weight = 20.5
    fb.insert.total = 31.0
    matched = fb.query('(eq total (agg (always) (sum weight)))').each.to_a
    assert_equal(1, matched.size)
    assert_in_delta(31.0, matched[0].total, 0.0001)
  end
end
