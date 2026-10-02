# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase/taped'
require_relative '../test__helper'

class TestTapedGuards < Factbase::Test
  def test_refuses_a_wrong_operand_on_an_empty_receiver
    %i[| &].each do |op|
      assert_raises(ArgumentError, "#{op} on an empty receiver must still check its operand") do
        Factbase::Taped.new([]).public_send(op, 'not an array')
      end
    end
  end

  def test_refuses_a_wrong_operand_on_an_empty_argument
    %i[| &].each do |op|
      assert_raises(ArgumentError, "#{op} must refuse another Taped, empty or not") do
        Factbase::Taped.new([{ 'a' => 1 }]).public_send(op, Factbase::Taped.new([]))
      end
    end
  end
end
