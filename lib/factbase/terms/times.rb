# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# This class represents a 'times' term within the Factbase.
# It performs a multiplication operation over the given operands.
class Factbase::Times < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @times = Factbase::Arithmetic.new(:*, operands)
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Object] Result of the multiplication
  def evaluate(fact, maps, fb)
    @times.evaluate(fact, maps, fb)
  end
end
