# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# Represents a 'head' term in the Factbase.
# It retrieves the first N results from a query.
class Factbase::Head < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = 'head'
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] Always true
  def evaluate(_fact, _maps, _fb)
    true
  end

  def predict(maps, fb, params)
    assert_args(2)
    max = @operands[0]
    raise "An integer is expected as first argument of '#{@op}'" unless max.is_a?(Integer)
    term = @operands[1]
    raise "A term is expected, but '#{term}' provided" unless term.is_a?(Factbase::Term)
    fb.query(term, maps).each(fb, params).to_a
      .take(max)
      .map { |m| m.all_properties.to_h { |k| [k, m[k]] } }
  end
end
