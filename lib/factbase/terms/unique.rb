# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
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
    raise "Too few operands for 'unique' (at least 1 expected)" if @operands.empty?
    vv = (0..(@operands.size - 1)).map { |i| _values(i, fact, maps, fb) }
    return false if vv.any?(nil)
    pass = true
    Enumerator.product(*vv).to_a.each do |t|
      pass = false if @seen.include?(t)
      @seen << t
    end
    pass
  end
end
