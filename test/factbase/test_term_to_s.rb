# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase/term'

require_relative '../test__helper'

# Term text test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTermToS < Factbase::Test
  def test_conversion_terms_name_their_operator
    assert_equal('(to_integer foo)', Factbase::ToInteger.new([:foo]).to_s)
    assert_equal('(to_float foo)', Factbase::ToFloat.new([:foo]).to_s)
    assert_equal('(to_string foo)', Factbase::ToString.new([:foo]).to_s)
    assert_equal('(to_time foo)', Factbase::ToTime.new([:foo]).to_s)
  end

  def test_arithmetic_terms_name_their_operator
    assert_equal('(plus 1 2)', Factbase::Plus.new([1, 2]).to_s)
    assert_equal('(minus 5 2)', Factbase::Minus.new([5, 2]).to_s)
    assert_equal('(times 3 4)', Factbase::Times.new([3, 4]).to_s)
    assert_equal('(div 6 2)', Factbase::Div.new([6, 2]).to_s)
  end

  def test_different_arithmetic_operands_print_differently
    assert_equal(
      ['(plus 1 2)', '(plus 40 2)', '(plus foo 2)'],
      [[1, 2], [40, 2], [:foo, 2]].map { |o| Factbase::Plus.new(o).to_s }
    )
    refute_equal(Factbase::Div.new([6, 2]).to_s, Factbase::Div.new([6, 3]).to_s)
  end

  def test_terms_without_a_symbol_operator_print_their_name
    {
      Factbase::Absent => 'absent',
      Factbase::As => 'as',
      Factbase::Concat => 'concat',
      Factbase::Defn => 'defn',
      Factbase::Env => 'env',
      Factbase::Exists => 'exists',
      Factbase::Join => 'join',
      Factbase::Many => 'many',
      Factbase::Matches => 'matches',
      Factbase::Nil => 'nil',
      Factbase::One => 'one',
      Factbase::Prev => 'prev',
      Factbase::Size => 'size',
      Factbase::Sprintf => 'sprintf',
      Factbase::Type => 'type',
      Factbase::Undef => 'undef',
      Factbase::Unique => 'unique',
      Factbase::Zero => 'zero'
    }.each do |klass, name|
      assert_equal("(#{name} foo)", klass.new([:foo]).to_s, "#{klass} prints no operator")
    end
  end
end
