# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
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
    raise "A symbol is expected as first argument of 'sorted'" unless prop.is_a?(Symbol)
    term = @operands[1]
    raise "A term is expected, but '#{term}' provided" unless term.is_a?(Factbase::Term)
    fb.query(term, maps).each(fb, params).to_a
      .reject { |m| m[prop].nil? }
      .sort_by { |m| m[prop].first }
      .map { |m| m.all_properties.to_h { |k| [k, m[k]] } }
  end
end
