# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# This class represents a 'sorted' term in the Factbase.
# It evaluates whether the given facts satisfy the sorted condition.
class Factbase::Sorted < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = 'sorted'
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] _fact The fact
  # @param [Array<Factbase::Fact>] _maps All maps available
  # @param [Factbase] _fb Factbase to use for sub-queries
  # @return [Boolean] Whether the value is sorted
  def evaluate(_fact, _maps, _fb)
    true
  end

  def predict(maps, fb, params)
    assert_args(2)
    prop = @operands[0]
    raise(ArgumentError, "A symbol is expected as first argument of 'sorted'") unless prop.is_a?(Symbol)
    term = @operands[1]
    raise(ArgumentError, "A term is expected, but '#{term}' provided") unless term.is_a?(Factbase::Term)
    blank, valued = fb.query(term, maps).each(fb, params).to_a.partition { |m| m[prop].nil? }
    _flatten(_ordered(valued, prop) + blank)
  end

  private

  # Sort the facts by the property, keeping the order of the equal ones.
  # @param [Array<Factbase::Fact>] valued Facts that have the property
  # @param [Symbol] prop The property to sort by
  # @return [Array<Factbase::Fact>] Sorted facts
  def _ordered(valued, prop)
    valued.each_with_index.sort do |(one, first), (two, second)|
      left = one[prop].first
      right = two[prop].first
      answer = left <=> right
      if answer.nil?
        raise(
          ArgumentError,
          "Can't compare '#{left}' (#{left.class}) with '#{right}' (#{right.class}) in the '#{prop}' property"
        )
      end
      answer.zero? ? first <=> second : answer
    end.map!(&:first)
  end
end
