# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
#
# The Factbase::As class is a specialized term that evaluates
# and assigns values to a specific attribute of a fact.
class Factbase::As < Factbase::TermBase
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
  # @return [Boolean] True if succeeded
  def evaluate(fact, maps, fb)
    assert_args(2)
    a = @operands[0]
    raise "A symbol is expected as first argument of 'as'" unless a.is_a?(Symbol)
    vv = _values(1, fact, maps, fb)
    vv&.each { |v| fact.send(:"#{a}=", v) }
    true
  end
end
