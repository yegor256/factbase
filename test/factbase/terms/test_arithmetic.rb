# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/arithmetic'
require_relative '../../test__helper'

# Test for arithmetic terms.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestArithmetic < Factbase::Test
  def test_refuses_to_multiply_a_time
    assert_raises(ArgumentError, 'multiplying a time is not refused') do
      Factbase::Arithmetic.new(:*, [:t, 2]).evaluate(fact('t' => Time.utc(2026, 1, 1)), [], Factbase.new)
    end
  end

  def test_refuses_to_divide_a_time
    assert_raises(ArgumentError, 'dividing a time is not refused') do
      Factbase::Arithmetic.new(:quo, [:t, 2]).evaluate(fact('t' => Time.utc(2026, 1, 1)), [], Factbase.new)
    end
  end

  def test_refuses_a_time_on_the_right_of_plus
    assert_raises(ArgumentError, 'a time on the right of plus is not refused') do
      Factbase::Arithmetic.new(:+, [60, :t]).evaluate(fact('t' => Time.utc(2026, 1, 1)), [], Factbase.new)
    end
  end

  def test_refuses_to_add_two_times
    assert_raises(ArgumentError, 'adding two times is not refused') do
      Factbase::Arithmetic.new(:+, %i[t t]).evaluate(fact('t' => Time.utc(2026, 1, 1)), [], Factbase.new)
    end
  end

  def test_subtracts_two_times
    assert_in_delta(
      3600.0,
      Factbase::Arithmetic.new(:-, %i[b a]).evaluate(
        fact('a' => Time.utc(2026, 1, 1, 10), 'b' => Time.utc(2026, 1, 1, 11)), [], Factbase.new
      ),
      0.001,
      'the distance between two times is not their difference in seconds'
    )
  end
end
