# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# Term 'compare'.
# Compares two values using a specified operation.
class Factbase::Compare < Factbase::TermBase
  # Constructor.
  # @param [Symbol] operation Operation to perform, e.g. :>, :<, :<=, :>=, :==
  # @param [Array] operands Operands
  def initialize(operation, operands)
    super()
    @op = operation
    @operands = operands
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] The result of the comparison
  def evaluate(fact, maps, fb)
    assert_args(2)
    lefts = _values(0, fact, maps, fb)
    return false if lefts.nil?
    rights = _values(1, fact, maps, fb)
    return false if rights.nil?
    lefts.any? do |l|
      l = l.floor if l.is_a?(Time) && @op == :==
      rights.any? do |r|
        r = r.floor if r.is_a?(Time) && @op == :==
        l.send(@op, r)
      end
    end
  end
end
