# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/when'

# Test for the 'when' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestWhen < Factbase::Test
  def test_when_parametrized
    [
      [Factbase::Always.new, Factbase::Always.new, true],
      [Factbase::Never.new,  Factbase::Always.new, true],
      [Factbase::Never.new,  Factbase::Never.new,  true],
      [Factbase::Always.new, Factbase::Never.new,  false]
    ].each do |first, second, should_pass|
      t = Factbase::When.new([first, second])
      if should_pass
        assert(t.evaluate(fact, [], Factbase.new))
      else
        refute(t.evaluate(fact, [], Factbase.new))
      end
    end
  end

  def test_evaluates_first_operand_only_once
    counter = CountingTerm.new(true)
    t = Factbase::When.new([counter, Factbase::Always.new])
    assert(t.evaluate(fact, [], Factbase.new))
    assert_equal(1, counter.calls)
  end

  def test_evaluates_first_operand_only_once_when_false
    counter = CountingTerm.new(false)
    t = Factbase::When.new([counter, Factbase::Always.new])
    assert(t.evaluate(fact, [], Factbase.new))
    assert_equal(1, counter.calls)
  end

  def test_unique_inside_when_passes_all_facts
    fb = Factbase.new
    3.times { fb.insert.x = 1 }
    assert_equal(3, fb.query('(when (unique x) (eq x 1))').each.to_a.size)
  end

  def test_unique_inside_when_with_distinct_values
    fb = Factbase.new
    [1, 2, 3].each { |v| fb.insert.x = v }
    assert_equal(1, fb.query('(when (unique x) (eq x 1))').each.to_a.size)
  end

  # Term that counts how many times it is evaluated.
  class CountingTerm < Factbase::TermBase
    attr_reader :calls

    def initialize(result)
      super()
      @operands = []
      @op = :counting
      @result = result
      @calls = 0
    end

    def evaluate(_fact, _maps, _fb)
      @calls += 1
      @result
    end
  end
end
