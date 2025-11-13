# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
require_relative 'compare'

# Represents a less-than term in the Factbase system.
# This class is used to evaluate whether a given fact satisfies
# a less-than comparison with the specified operands.
class Factbase::Lt < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @op = Factbase::Compare.new(:<, operands)
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] The result of the less-than comparison
  def evaluate(fact, maps, fb)
    @op.evaluate(fact, maps, fb)
  end
end
