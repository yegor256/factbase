# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
require_relative 'compare'

# Represents a 'starts_with' term in the Factbase.
# Returns true if any value of the left operand starts with any value of the right.
class Factbase::StartsWith < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @op = Factbase::Compare.new(:start_with?, operands)
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] True if any left value starts with any right value
  def evaluate(fact, maps, fb)
    @op.evaluate(fact, maps, fb)
  end
end
