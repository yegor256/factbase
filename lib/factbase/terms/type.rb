# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# Represents a type term in the Factbase.
# This class evaluates the type of the given operand
# based on the provided fact, maps, and factbase.
class Factbase::Type < Factbase::TermBase
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
  # @return [String] Type of the operand
  def evaluate(fact, _maps, _fb)
    assert_args(1)
    v = _by_symbol(0, fact)
    return 'nil' if v.nil?
    v = v[0] if v.respond_to?(:each) && v.size == 1
    v.class.to_s
  end
end
