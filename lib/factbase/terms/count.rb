# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# The 'count' term is used to perform a count operation on a set of maps.
class Factbase::Count < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = :count
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] _fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] _fb Factbase to use for sub-queries
  # @return [Integer] The count of maps
  def evaluate(_fact, maps, _fb)
    maps.size
  end
end
