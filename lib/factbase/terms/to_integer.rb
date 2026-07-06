# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# Represents an integer conversion term 'to_integer'.
# This class is used to evaluate a term and return its integer representation.
class Factbase::ToInteger < Factbase::TermBase
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
  # @return [Integer] Integer representation of the value
  def evaluate(fact, maps, fb)
    assert_args(1)
    vv = _values(0, fact, maps, fb)
    return if vv.nil?
    to_int(vv[0])
  end

  private

  def to_int(value)
    Integer(value)
  rescue ArgumentError => e
    raise(RuntimeError, "Cannot convert '#{value}' to Integer in (to_integer ...): #{e.message}")
  end
end
