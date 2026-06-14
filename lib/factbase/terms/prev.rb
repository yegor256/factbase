# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# The Factbase::Prev class returns the previous value of a property
# during iteration, enabling comparisons between consecutive facts.
class Factbase::Prev < Factbase::TermBase
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
  # @return [Object] The previous value
  def evaluate(fact, maps, fb)
    assert_args(1)
    @prev.tap { @prev = _values(0, fact, maps, fb) }
  end
end
