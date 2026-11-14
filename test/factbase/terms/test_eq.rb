# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/eq'
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

  def test_returns_false_when_left_absent_with_literal
    refute(Factbase::Eq.new([:number, 42]).evaluate(fact('other' => 42), [], Factbase.new))
  end

  def test_returns_false_when_both_operands_absent
    refute(Factbase::Eq.new(%i[foo bar]).evaluate(fact('other' => 42), [], Factbase.new))
  end

  def test_returns_false_when_left_absent_and_right_present
    refute(Factbase::Eq.new(%i[foo bar]).evaluate(fact('bar' => 42), [], Factbase.new))
  end

  def test_evaluates_prev_on_right_when_left_is_absent
    fb = Factbase.new
    fb.insert.then do |f|
      f.id = 1
      f.status = 'active'
    end
    fb.insert.then do |f|
      f.id = 2
    end
    fb.insert.then do |f|
      f.id = 3
      f.status = 'active'
    end
    fb.insert.then do |f|
      f.id = 4
      f.status = 'active'
    end
    assert_equal([4], fb.query('(eq status (prev status))').each.to_a.map(&:id))
  end

  def test_evaluates_nested_stateful_term_when_left_is_absent
    fb = Factbase.new
    fb.insert.then do |f|
      f.id = 1
      f.count = 10
    end
    fb.insert.then do |f|
      f.id = 2
    end
    fb.insert.then do |f|
      f.id = 3
      f.count = 11
    end
    fb.insert.then do |f|
      f.id = 4
      f.count = 12
    end
    assert_equal([4], fb.query('(eq count (plus (prev count) 1))').each.to_a.map(&:id))
  end
end
