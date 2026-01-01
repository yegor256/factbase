# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
require_relative 'arithmetic'

# Represents a Plus term in the Factbase system.
# This class is used to perform addition operations on operands.
class Factbase::Plus < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @plus = Factbase::Arithmetic.new(:+, operands)
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Object] Result of the addition
  def evaluate(fact, maps, fb)
    @plus.evaluate(fact, maps, fb)
  end
end
