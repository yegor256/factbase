# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# Checks that the operand has a value for the current fact: a property name,
# e.g. <tt>(exists x)</tt>, or a term, e.g. <tt>(exists (eq x 1))</tt>.
class Factbase::Exists < Factbase::TermBase
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
  # @return [Boolean] True if exists
  def evaluate(fact, maps, fb)
    assert_args(1)
    !_operand(0, fact, maps, fb).nil?
  end
end
