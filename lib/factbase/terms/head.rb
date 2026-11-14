# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
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
  # @param [Factbase::Fact] _fact The fact
  # @param [Array<Factbase::Fact>] _maps All maps available
  # @param [Factbase] _fb Factbase to use for sub-queries
  # @return [Boolean] Always true
  def evaluate(_fact, _maps, _fb)
    true
  end

  def predict(maps, fb, params)
    assert_args(2)
    vv = _values(0, params, maps, fb) || []
    max = vv.first
    raise(ArgumentError, "An integer is expected as first argument of '#{@op}'") unless vv.one? && max.is_a?(Integer)
    raise(ArgumentError, "A non-negative count is expected by '#{@op}', but #{max} provided") if max.negative?
    term = @operands[1]
    raise(ArgumentError, "A term is expected, but '#{term}' provided") unless term.is_a?(Factbase::Term)
    _flatten(fb.query(term, maps).each(fb, params).take([max, maps.size].min))
  end
end
