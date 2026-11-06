# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# Represents an 'nth' term in the Factbase.
# Retrieves the value of a specified key from the nth map.
class Factbase::Nth < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = :nth
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Object] The value of the specified key from the nth map
  def evaluate(fact, maps, fb)
    assert_args(2)
    pos = _values(0, fact, maps, fb)
    unless pos&.size == 1 && pos[0].is_a?(Integer)
      raise(ArgumentError, "An integer is expected, but #{@operands[0]} provided")
    end
    pos = pos[0]
    raise(ArgumentError, "A non-negative position is expected, but #{pos} provided") if pos.negative?
    k = @operands[1]
    raise(ArgumentError, "A symbol is expected, but #{k} provided") unless k.is_a?(Symbol)
    return if pos >= maps.size
    m = maps[pos]
    return if m.nil?
    m[k.to_s]&.dup
  end
end
