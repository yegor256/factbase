# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
require_relative 'compare'

# Represents a 'contains' term in the Factbase.
# Returns true if any value of the left operand contains any value of the right
# as a substring. Operates on string values via `String#include?`.
class Factbase::Contains < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @op = Factbase::Compare.new(:include?, operands)
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] True if any left value includes any right value
  def evaluate(fact, maps, fb)
    @op.evaluate(fact, maps, fb)
  end
end
