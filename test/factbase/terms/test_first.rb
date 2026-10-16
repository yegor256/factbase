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
end
