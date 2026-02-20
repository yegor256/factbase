# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# A class representing a traced term in the factbase.
# This class is responsible for evaluating a term and printing
# its evaluation result for tracing purposes.
class Factbase::Traced < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = 'traced'
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Object] Return value of the traced term
  def evaluate(fact, maps, fb)
    assert_args(1)
    t = @operands[0]
    raise "A term is expected, but '#{t}' provided" unless t.is_a?(Factbase::Term)
    r = t.evaluate(fact, maps, fb)
    puts "#{self} -> #{r}" # rubocop:disable Lint/Debugger
    r
  end
end
