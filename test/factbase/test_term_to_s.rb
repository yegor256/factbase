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
