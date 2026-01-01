# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
require_relative 'boolean'
# The 'not' term that negates a boolean operand.
# Logical negation (NOT) of an operand.
class Factbase::Not < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = :not
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @return [Boolean] Negated boolean result of the operand
  def evaluate(fact, maps, fb)
    assert_args(1)
    !Factbase::Boolean.new(_values(0, fact, maps, fb), @operands[0]).bool?
  end
end
