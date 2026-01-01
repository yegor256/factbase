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
  # @param [Factbase::Fact] _fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] _fb Factbase to use for sub-queries
  # @return [Object] The value of the specified key from the nth map
  def evaluate(_fact, maps, _fb)
    assert_args(2)
    pos = @operands[0]
    raise "An integer is expected, but #{pos} provided" unless pos.is_a?(Integer)
    k = @operands[1]
    raise "A symbol is expected, but #{k} provided" unless k.is_a?(Symbol)
    m = maps[pos]
    return nil if m.nil?
    m[k.to_s]
  end
end
