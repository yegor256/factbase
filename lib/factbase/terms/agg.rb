# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# The term 'agg' that aggregates.
class Factbase::Agg < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands = [])
    super()
    @operands = operands
    @op = :agg
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Object] The result of evaluation
  def evaluate(fact, maps, fb)
    assert_args(2)
    selector = @operands[0]
    unless selector.is_a?(Factbase::Term) || selector.is_a?(Factbase::TermBase)
      raise "A term is expected, but '#{selector}' provided"
    end
    term = @operands[1]
    unless term.is_a?(Factbase::Term) || term.is_a?(Factbase::TermBase)
      raise "A term is expected, but '#{term}' provided"
    end
    subset = fb.query(selector, maps).each(fb, fact).to_a
    term.evaluate(nil, subset, fb)
  end
end
