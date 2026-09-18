# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# The Factbase::Unique class provides functionality for evaluating the uniqueness
# of terms based on provided operands and facts.
class Factbase::Unique < Factbase::TermBase
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
  # @return [Boolean] True if the value is unique, false otherwise
  def evaluate(fact, maps, fb)
    @seen = Set.new if @seen.nil?
    raise(ArgumentError, "Too few operands for 'unique' (at least 1 expected)") if @operands.empty?
    vv = (0..(@operands.size - 1)).map { |i| _values(i, fact, maps, fb) }
    return false if vv.any?(nil)
    tuples = Enumerator.product(*vv).to_a
    tuples.filter_map { |t| @seen.add?(t.map { |v| _key(v) }) }.any?
  end

  private

  # The form a value is remembered in.
  #
  # A Set tells its members apart with +eql?+, which says that 1 and 1.0 are
  # two values, while +eq+ compares with +==+, which says they are one. A
  # number is therefore remembered as an exact rational, so that both of them
  # count as the value already seen.
  #
  # @param [Object] value The value, as the fact holds it
  # @return [Object] The form to remember it in
  def _key(value)
    return value unless value.is_a?(Integer) || value.is_a?(Float)
    return value if value.is_a?(Float) && !value.finite?
    Rational(value)
  end
end
