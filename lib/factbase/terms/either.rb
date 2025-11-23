# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# Represents a logical "either" term.
# The term evaluates its operands and returns the first non-nil value.
class Factbase::Either < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = :either
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Object] First operand if not nil, otherwise second operand
  # @return [Boolean] True if first operand is false OR both are true
  def evaluate(fact, maps, fb)
    assert_args(2)
    v = _values(0, fact, maps, fb)
    return v unless v.nil?
    _values(1, fact, maps, fb)
  end
end
