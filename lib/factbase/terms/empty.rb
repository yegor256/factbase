# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# The 'empty' term checks for emptiness in the results of a query evaluation.
class Factbase::Empty < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = :empty
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] The result of the emptiness check
  def evaluate(fact, maps, fb)
    assert_args(1)
    term = @operands[0]
    unless term.is_a?(Factbase::Term) || term.is_a?(Factbase::TermBase)
      raise "A term is expected, but '#{term}' provided"
    end
    # rubocop:disable Lint/UnreachableLoop
    fb.query(term, maps).each(fb, fact) do
      return false
    end
    # rubocop:enable Lint/UnreachableLoop
    true
  end
end
