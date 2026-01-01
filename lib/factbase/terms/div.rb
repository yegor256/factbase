# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# This class represents a 'div' term within the Factbase.
# It performs a division operation over the given operands.
class Factbase::Div < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @div = Factbase::Arithmetic.new(:/, operands)
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Object] Result of the division
  def evaluate(fact, maps, fb)
    @div.evaluate(fact, maps, fb)
  end
end
