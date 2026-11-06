# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/prev'

require_relative '../../test__helper'

class TestPrev < Factbase::Test
  def test_prev
    t = Factbase::Prev.new([:foo])
    assert_nil(t.evaluate(fact('foo' => 41), [], Factbase.new))
    assert_equal([41], t.evaluate(fact('foo' => 5), [], Factbase.new))
    assert_equal([5], t.evaluate(fact('foo' => 6), [], Factbase.new))
  end

  def test_prev_with_missing_left_property
    fb = Factbase.new
    fb.insert.then do |f|
      f.id = 1
      f.status = 'up'
    end
    fb.insert.then do |f|
      f.id = 2
    end
    fb.insert.then do |f|
      f.id = 3
      f.status = 'up'
    end
    assert_empty(fb.query('(eq status (prev status))').each.to_a)
  end

  def test_prev_on_both_sides
    fb = Factbase.new
    fb.insert.then do |f|
      f.id = 1
    end
    fb.insert.then do |f|
      f.id = 2
    end
    fb.insert.then do |f|
      f.id = 3
    end
    assert_equal([2, 3], fb.query('(eq (prev id) (prev id))').each.to_a.map(&:id))
  end

  def test_prev_skips_when_intervening_fact_lacks_property
    fb = Factbase.new
    fb.insert.then do |f|
      f.id = 1
      f.status = 'up'
    end
    fb.insert.then do |f|
      f.id = 2
    end
    fb.insert.then do |f|
      f.id = 3
      f.status = 'up'
    end
    fb.insert.then do |f|
      f.id = 4
      f.status = 'up'
    end
    assert_equal([4], fb.query('(eq status (prev status))').each.to_a.map(&:id))
  end
end
