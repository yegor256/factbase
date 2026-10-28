# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../accum'
require_relative '../fact'
require_relative '../flatten'
require_relative '../tee'
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
    term.forget
    params = params.transform_keys(&:to_s) if params.is_a?(Hash)
    maybe = term.predict(maps, fb, Factbase::Tee.new({}, params))
    maybe ||= maps unless maybe.equal?(maps)
    blank = []
    valued = []
    maybe.each do |m|
      acc = Factbase::Accum.new(Factbase::Tee.new(Factbase::Fact.new(m), params), {}, false)
      r = term.evaluate(acc, maps, fb)
      unless r.is_a?(TrueClass) || r.is_a?(FalseClass)
        raise(ArgumentError, "Unexpected evaluation result of type #{r.class}, must be Boolean at #{term}")
      end
      next unless r
      v = acc[prop]
      if v.nil?
        blank << m
      else
        valued << [m, v]
      end
    end
    valued.sort_by!.with_index { |(_m, v), i| [Factbase::Flatten.key(v.first), i] }
    valued.map!(&:first).concat(blank)
  end
end
