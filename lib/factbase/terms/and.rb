# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
require_relative 'boolean'
require_relative 'simplified'
# The 'and' term that represents a logical AND operation between multiple operands.
class Factbase::And < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = :and
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @return [Boolean] True if all operands evaluate to true, false otherwise
  def evaluate(fact, maps, fb)
    (0..(@operands.size - 1)).each do |i|
      return false unless Factbase::Boolean.new(_values(i, fact, maps, fb), @operands[i]).bool?
    end
    true
  end

  def simplify
    unique = Factbase::Simplified.new(@operands).unique
    return unique[0] if unique.size == 1
    Factbase::Term.new(@op, unique)
  end
end
