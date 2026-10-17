# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
require_relative 'compare'

# Represents an equality term in the Factbase.
# This class encapsulates the evaluation of equality comparisons
# between operands within the context of a Factbase.
class Factbase::Eq < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @op = Factbase::Compare.new(:==, operands)
    @operands = operands
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] The result of the equality comparison
  def evaluate(fact, maps, fb)
    assert_args(2)
    lefts = _values(0, fact, maps, fb)
    return false if lefts.nil?
    rights = _values(1, fact, maps, fb)
    return false if rights.nil?
    if lefts.size > 8 || rights.size > 8
      target, pool = lefts.size <= rights.size ? [lefts, rights] : [rights, lefts]
      set = pool.to_set { |v| normalize(v) }
      target.any? { |v| set.include?(normalize(v)) }
    else
      @op.evaluate(fact, maps, fb)
    end
  end

  private

  # Normalize value for equality comparison.
  # @param [Object] val Value to normalize
  # @return [Object] Normalized value
  def normalize(val)
    return val.floor if val.is_a?(Time)
    return Rational(val) if val.is_a?(Integer) || (val.is_a?(Float) && val.finite?)
    val
  end
end
