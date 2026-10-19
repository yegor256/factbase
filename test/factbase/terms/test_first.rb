# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/first'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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

  def test_cannot_read_parameter_as_property
    seed = Random.new_seed
    rnd = Random.new(seed)
    name = "$w#{Array.new(rnd.rand(1..16)) { [*'a'..'z'].sample(random: rnd) }.join}"
    assert_raises(ArgumentError, "first read the parameter #{name} as a property, seed #{seed}") do
      Factbase::First.new([name.to_sym]).evaluate(fact, [{ name => [rnd.rand(1..1000)] }], Factbase.new)
    end
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
