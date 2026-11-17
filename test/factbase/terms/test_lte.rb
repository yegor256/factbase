# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/lte'
require_relative '../../test__helper'

# Tests for the 'lte' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestLte < Factbase::Test
  def test_compares_less_than_or_equal
    t = Factbase::Lte.new([:number, 42])
    assert(t.evaluate(fact('number' => 10), [], Factbase.new))
    assert(t.evaluate(fact('number' => 42), [], Factbase.new))
  end

  def test_compares_not_greater_than
    refute(Factbase::Lte.new([:number, 42]).evaluate(fact('number' => 100), [], Factbase.new))
  end

  def test_returns_false_when_left_absent_with_literal
    refute(Factbase::Lte.new([:number, 42]).evaluate(fact('other' => 10), [], Factbase.new))
  end

  def test_returns_false_when_both_operands_absent
    refute(Factbase::Lte.new(%i[foo bar]).evaluate(fact('other' => 42), [], Factbase.new))
  end

  def test_returns_false_when_left_absent_and_right_present
    refute(Factbase::Lte.new(%i[foo bar]).evaluate(fact('bar' => 42), [], Factbase.new))
  end

  def test_evaluates_prev_on_right_when_left_is_absent
    fb = Factbase.new
    fb.insert.then do |f|
      f.id = 1
      f.score = 50
    end
    fb.insert.then do |f|
      f.id = 2
    end
    fb.insert.then do |f|
      f.id = 3
      f.score = 40
    end
    fb.insert.then do |f|
      f.id = 4
      f.score = 40
    end
    assert_equal([4], fb.query('(lte score (prev score))').each.to_a.map(&:id))
  end

  def test_evaluates_nested_stateful_term_when_left_is_absent
    fb = Factbase.new
    fb.insert.then do |f|
      f.id = 1
      f.score = 50
    end
    fb.insert.then do |f|
      f.id = 2
    end
    fb.insert.then do |f|
      f.id = 3
      f.score = 40
    end
    fb.insert.then do |f|
      f.id = 4
      f.score = 35
    end
    assert_equal([4], fb.query('(lte score (minus (prev score) 5))').each.to_a.map(&:id))
  end
end
