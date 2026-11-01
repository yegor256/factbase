# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/first'

require_relative '../../test__helper'

# Test for 'first' term.
# Author:: Vlodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestFirst < Factbase::Test
  def test_first_several
    assert_equal(1, Factbase::First.new([:first]).evaluate(fact, [{ 'first' => 1 }], Factbase.new))
  end

  def test_first_absent
    assert_nil(Factbase::First.new([:absent]).evaluate(fact, {}, Factbase.new))
  end

  def test_modifying_returned_array_does_not_alter_fact_via_append
    fb = Factbase.new
    f = fb.insert
    f.x = 10
    f.x = 20
    fb.query('(first x)').one << 99
    assert_equal([10, 20], f['x'])
    assert_equal(10, f.x)
  end

  def test_modifying_returned_array_does_not_alter_fact_via_index_assignment
    fb = Factbase.new
    f = fb.insert
    f.x = 10
    f.x = 20
    fb.query('(first x)').one[0] = 99
    assert_equal([10, 20], f['x'])
    assert_equal(10, f.x)
  end

  def test_evaluating_first_returns_duplicate_of_array
    map = { 'num' => [1, 2, 3] }
    v = Factbase::First.new([:num]).evaluate(fact, [map], Factbase.new)
    v << 99
    v[0] = 42
    assert_equal([1, 2, 3], map['num'])
  end
end
