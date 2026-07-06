# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# Represents a float conversion term 'to_float'.
# This class is used to evaluate a term and return its float representation.
class Factbase::ToFloat < Factbase::TermBase
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
  # @return [Float] Float representation of the value
  def evaluate(fact, maps, fb)
    assert_args(1)
    vv = _values(0, fact, maps, fb)
    return if vv.nil?
    to_float(vv[0])
  end

  private

  def to_float(value)
    Float(value)
  rescue ArgumentError => e
    raise(RuntimeError, "Cannot convert '#{value}' to Float in (to_float ...): #{e.message}")
  end
end
