# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# Represents a string conversion term 'to_string'.
# This class is used to evaluate a term and return its string representation.
class Factbase::ToString < Factbase::TermBase
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
  # @return [String] The same value as string
  def evaluate(fact, maps, fb)
    assert_args(1)
    vv = _values(0, fact, maps, fb)
    return nil if vv.nil?
    vv[0].to_s
  end
end
