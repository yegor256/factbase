# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../test__helper'

class TestCompareOperand < Factbase::Test
  def test_names_the_operands_of_a_wrong_right_side
    fb = Factbase.new
    fb.insert.name = 'hello'
    %w[contains starts_with ends_with].each do |op|
      e =
        assert_raises(StandardError, "#{op} with a number on the right must explain itself") do
          fb.query("(#{op} name 7)").each.to_a
        end
      assert_includes(e.message, 'Cannot compare', "#{op} lost its own message")
      assert_includes(e.message, 'Integer', "#{op} did not name the class of the right operand")
    end
  end
end
