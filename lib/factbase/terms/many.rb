# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# Represents a 'many' term in the Factbase that evaluates to true if a property
# has multiple values. This class is used to check if there are more
# than one values associated with a specific property in a fact.
class Factbase::Many < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] True if many
  def evaluate(fact, maps, fb)
    assert_args(1)
    v = _values(0, fact, maps, fb)
    !v.nil? && v.size > 1
  end
end
