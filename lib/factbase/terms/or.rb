# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
require_relative 'boolean'
require_relative 'simplified'
# The 'or' term that represents a logical OR operation between multiple operands.
class Factbase::Or < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = :or
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] True if any operand evaluates to true, false otherwise
  def evaluate(fact, maps, fb)
    (0..(@operands.size - 1)).each do |i|
      return true if Factbase::Boolean.new(_values(i, fact, maps, fb), @operands[i]).bool?
    end
    false
  end

  def simplify
    Factbase::Term.new(@op, Factbase::Simplified.new(@operands).unique)
  end
end
