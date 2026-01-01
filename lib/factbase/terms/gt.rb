# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
require_relative 'compare'

# Represents a greater-than comparison term in the Factbase.
# This class is used to evaluate whether a given fact satisfies
# the greater-than condition with the provided operands.
class Factbase::Gt < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @op = Factbase::Compare.new(:>, operands)
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] The result of the greater-than comparison
  def evaluate(fact, maps, fb)
    @op.evaluate(fact, maps, fb)
  end
end
