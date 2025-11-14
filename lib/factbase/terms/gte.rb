# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
require_relative 'compare'

# It represents a term for evaluating whether a set of operands satisfies
# the "greater-than-or-equal-to" (>=) condition within the context of a factbase.
class Factbase::Gte < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @op = Factbase::Compare.new(:>=, operands)
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] The result of the greater-than-or-equal comparison
  def evaluate(fact, maps, fb)
    @op.evaluate(fact, maps, fb)
  end
end
