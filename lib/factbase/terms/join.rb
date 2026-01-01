# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# The Factbase::Join class is a specialized term that performs
# join operations between facts based on specified attribute mappings.
class Factbase::Join < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] True if succeeded
  def evaluate(fact, maps, fb)
    assert_args(2)
    jumps = @operands[0]
    raise "A string is expected as first argument of 'join'" unless jumps.is_a?(String)
    jumps = jumps.split(',')
      .map(&:strip)
      .map { |j| j.split('<=').map(&:strip) }
      .map { |j| j.size == 1 ? [j[0], j[0]] : j }
    term = @operands[1]
    raise "A term is expected, but '#{term}' provided" unless term.is_a?(Factbase::Term)
    subset = fb.query(term, maps).each(fb, fact).to_a
    subset.each do |s|
      jumps.each do |to, from|
        s[from]&.each do |v|
          fact.send(:"#{to}=", v)
        end
      end
    end
    true
  end
end
