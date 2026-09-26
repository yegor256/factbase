# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/prev'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

class TestPrev < Factbase::Test
  def test_prev
    t = Factbase::Prev.new([:foo])
    assert_nil(t.evaluate(fact('foo' => 41), [], Factbase.new))
    assert_equal([41], t.evaluate(fact('foo' => 5), [], Factbase.new))
    assert_equal([5], t.evaluate(fact('foo' => 6), [], Factbase.new))
  end

  def test_forgets_value_of_previous_run
    seed = Random.new_seed
    rnd = Random.new(seed)
    fb = Factbase.new
    Array.new(rnd.rand(2..9)) { rnd.rand(-1000..1000) }.each { |n| fb.insert.num = n }
    q = fb.query('(as p (prev num))')
    q.each.to_a
    assert_nil(q.each.to_a.first['p'], "first fact of the second run sees a value of the first run, seed #{seed}")
  end

  def test_forgets_value_when_nested_deeper
    seed = Random.new_seed
    rnd = Random.new(seed)
    fb = Factbase.new
    Array.new(rnd.rand(2..9)) { rnd.rand(-1000..1000) }.each { |n| fb.insert.num = n }
    q = fb.query('(and (exists num) (as p (prev num)))')
    q.each.to_a
    assert_nil(q.each.to_a.first['p'], "nested prev keeps the value of the previous run, seed #{seed}")
  end

  def test_forgets_value_before_deleting
    seed = Random.new_seed
    fb = Factbase.new
    num = Random.new(seed).rand(-1000..1000)
    2.times { fb.insert.num = num }
    q = fb.query('(eq num (prev num))')
    q.each.to_a
    assert_equal(1, q.delete!, "deleting after a run sees the value that run left behind, seed #{seed}")
  end
end
