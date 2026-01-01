# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# Factbase::Size is a term that calculates the size of an operand
# when evaluated on a given fact.
class Factbase::Size < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] _maps All maps available
  # @param [Factbase] _fb Factbase to use for sub-queries
  # @return [Integer] Size of the operand
  def evaluate(fact, _maps, _fb)
    assert_args(1)
    v = _by_symbol(0, fact)
    return 0 if v.nil?
    return 1 unless v.respond_to?(:to_a)
    v.size
  end
end
