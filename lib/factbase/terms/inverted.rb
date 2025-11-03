# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# Evaluates whether a value is inverted within a given factbase context.
class Factbase::Inverted < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = 'inverted'
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] _fact The fact
  # @param [Array<Factbase::Fact>] _maps All maps available
  # @param [Factbase] _fb Factbase to use for sub-queries
  # @return [Boolean] Whether the value is inverted
  def evaluate(_fact, _maps, _fb)
    true
  end

  def predict(maps, fb, params)
    assert_args(1)
    term = @operands[0]
    raise "A term is expected, but '#{term}' provided" unless term.is_a?(Factbase::Term)
    fb.query(term, maps).each(fb, params).to_a
      .reverse
      .map { |m| m.all_properties.to_h { |k| [k, m[k]] } }
  end
end
