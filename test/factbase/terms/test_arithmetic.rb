# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/plus'

require_relative '../../test__helper'

# Test for the operand guards of arithmetic terms.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestArithmetic < Factbase::Test
  def test_rejects_many_values_at_first_position
    assert_includes(
      assert_raises(ArgumentError) do
        Factbase::Plus.new(%i[a b]).evaluate(fact('a' => [1, 2], 'b' => 3), [], Factbase.new)
      end.message,
      'Too many values at first position, one expected'
    )
  end

  def test_returns_nil_when_second_position_is_absent
    assert_nil(Factbase::Plus.new(%i[a b]).evaluate(fact('a' => 1), [], Factbase.new))
  end

  def test_rejects_many_values_at_second_position
    assert_includes(
      assert_raises(ArgumentError) do
        Factbase::Plus.new(%i[a b]).evaluate(fact('a' => 1, 'b' => [2, 3]), [], Factbase.new)
      end.message,
      'Too many values at second position, one expected'
    )
  end
end
