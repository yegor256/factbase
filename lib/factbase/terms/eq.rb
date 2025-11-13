# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
require_relative 'compare'

# Represents an equality term in the Factbase.
# This class encapsulates the evaluation of equality comparisons
# between operands within the context of a Factbase.
class Factbase::Eq < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @op = Factbase::Compare.new(:==, operands)
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] The result of the equality comparison
  def evaluate(fact, maps, fb)
    @op.evaluate(fact, maps, fb)
  end
end
