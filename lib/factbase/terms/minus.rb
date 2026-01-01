# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# This class represents a 'minus' term within the Factbase.
# It performs a subtraction operation over the given operands.
class Factbase::Minus < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @minus = Factbase::Arithmetic.new(:-, operands)
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Object] Result of the subtraction
  def evaluate(fact, maps, fb)
    @minus.evaluate(fact, maps, fb)
  end
end
