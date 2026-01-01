# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# The 'first' term is used to retrieve the value of a specified key from the first map in a set of maps.
class Factbase::First < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = :first
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] _fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] _fb Factbase to use for sub-queries
  # @return [Object] The value of the specified key from the first map
  def evaluate(_fact, maps, _fb)
    assert_args(1)
    k = @operands[0]
    raise "A symbol is expected, but #{k} provided" unless k.is_a?(Symbol)
    first = maps[0]
    return nil if first.nil?
    first[k.to_s]
  end
end
