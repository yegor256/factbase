# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# This class represents a specialized 'sum' term.
# This term  calculates the sum of values for a specified key.
class Factbase::Sum < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = :sum
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] _fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] _fb Factbase to use for sub-queries
  # @return [Integer] The sum of values for the specified key across all maps
  def evaluate(_fact, maps, _fb)
    k = @operands[0]
    raise "A symbol is expected, but '#{k}' provided" unless k.is_a?(Symbol)
    sum = 0
    maps.each do |m|
      vv = m[k.to_s]
      next if vv.nil?
      vv = [vv] unless vv.respond_to?(:to_a)
      vv.each do |v|
        sum += v
      end
    end
    sum
  end
end
