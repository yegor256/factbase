# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# The `Factbase::Assert` class represents an assertion term in the Factbase system.
# It verifies that a given condition evaluates to true, raising an error with
# a specified message if the assertion fails.
class Factbase::Assert < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @op = 'assert'
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] Returns true if the assertion passes, otherwise raises an error with the provided message
  def evaluate(fact, maps, fb)
    assert_args(2)
    message = @operands[0]
    unless message.is_a?(String)
      raise ArgumentError,
            "A string is expected as first argument of 'assert', but '#{message}' provided"
    end
    t = @operands[1]
    unless t.is_a?(Factbase::Term)
      raise ArgumentError,
            "A term is expected as second argument of 'assert', but '#{t}' provided"
    end
    result = t.evaluate(fact, maps, fb)
    # Convert result to boolean-like evaluation
    # Arrays are truthy if they contain at least one truthy element
    truthy =
      if result.is_a?(Array)
        result.any? { |v| v && v != 0 }
      else
        result && result != 0
      end
    raise message unless truthy
    true
  end
end
