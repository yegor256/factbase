# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# Represents a term that checks if a certain condition exists within the factbase.
# This class evaluates whether a specific term exists in the given context of facts.
class Factbase::Exists < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] _maps All maps available
  # @param [Factbase] _fb Factbase to use for sub-queries
  # @return [Boolean] True if exists
  def evaluate(fact, _maps, _fb)
    assert_args(1)
    !_by_symbol(0, fact).nil?
  end
end
