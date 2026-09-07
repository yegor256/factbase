# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
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
      raise(ArgumentError, "A term is expected, but '#{selector}' provided")
    end
    term = @operands[1]
    unless term.is_a?(Factbase::Term) || term.is_a?(Factbase::TermBase)
      raise(ArgumentError, "A term is expected, but '#{term}' provided")
    end
    term.evaluate(nil, fb.query(selector, maps).each(fb, params(fact)).to_a, fb)
  end

  private

  # Extract the parameters made available to the outer query.
  # @param [Factbase::Fact] fact The fact being evaluated
  # @return [Hash] Parameters indexed by their names
  def params(fact)
    Context.new(fact, fact.all_properties.to_h { |name| [name, fact["$#{name}"]] }.compact)
  end

  # Values available to the selector of an aggregation.
  class Context
    # Ctor.
    # @param [Factbase::Fact] fact The outer fact
    # @param [Hash] params Parameters of the outer query
    def initialize(fact, params)
      @fact = fact
      @params = params
    end

    # Get a parameter, or the property of the outer fact when it is not a parameter.
    # @param [String] name Parameter or property name
    # @return [Object] The value
    def [](name)
      @params.fetch(name) { @fact[name] }
    end

    # List all available names.
    # @return [Array<String>] Names of the parameters and fact properties
    def all_properties
      @fact.all_properties | @params.keys
    end
  end
end
