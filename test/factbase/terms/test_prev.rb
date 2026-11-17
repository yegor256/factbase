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

  def test_prev_keeps_all_values
    t = Factbase::Prev.new([:value])
    assert_nil(t.evaluate(fact('value' => [10, 20]), [], Factbase.new))
    assert_equal([10, 20], t.evaluate(fact('value' => 30), [], Factbase.new))
    fb = Factbase.new
    first = fb.insert
    first.value = 10
    first.value = 20
    fb.insert.value = 30
    assert_equal(1, fb.query('(eq (prev value) 20)').each.to_a.size)
  end
end
