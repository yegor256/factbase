# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'
require_relative 'best'
require_relative 'base'

# The 'min' term.
# This term calculates the minimum value among the evaluated operands.
class Factbase::Min < Factbase::TermBase
  MIN = Factbase::Best.new { |v, b| v < b }

  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = :min
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] _fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] _fb Factbase to use for sub-queries
  # @return [Object] The minimum value among the evaluated operands
  def evaluate(_fact, maps, _fb)
    assert_args(1)
    MIN.evaluate(@operands[0], maps)
  end
end
