# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../accum'
require_relative '../fact'
require_relative '../tee'
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
    raise(ArgumentError, "A term is expected, but '#{term}' provided") unless term.is_a?(Factbase::Term)
    term.forget
    params = params.transform_keys(&:to_s) if params.is_a?(Hash)
    maybe = term.predict(maps, fb, Factbase::Tee.new({}, params))
    maybe ||= maps unless maybe.equal?(maps)
    result = []
    maybe.each do |m|
      r = term.evaluate(Factbase::Accum.new(Factbase::Tee.new(Factbase::Fact.new(m), params), {}, false), maps, fb)
      unless r.is_a?(TrueClass) || r.is_a?(FalseClass)
        raise(ArgumentError, "Unexpected evaluation result of type #{r.class}, must be Boolean at #{term}")
      end
      result << m if r
    end
    result.reverse!
  end
end
