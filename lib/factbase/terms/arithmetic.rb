# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# Factbase::Arithmetic is a class for performing arithmetic operations.
class Factbase::Arithmetic < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operation, operands)
    super()
    @op = operation
    @operands = operands
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Object] The result of the arithmetic operation
  def evaluate(fact, maps, fb)
    assert_args(2)
    lefts = _values(0, fact, maps, fb)
    return nil if lefts.nil?
    raise 'Too many values at first position, one expected' unless lefts.size == 1
    rights = _values(1, fact, maps, fb)
    return nil if rights.nil?
    raise 'Too many values at second position, one expected' unless rights.size == 1
    v = lefts[0]
    r = rights[0]
    if v.is_a?(Time) && r.is_a?(String)
      (num, units) = r.split
      num = num.to_i
      r =
        case units
        when 'seconds', 'second'
          num
        when 'minutes', 'minute'
          num * 60
        when 'hours', 'hour'
          num * 60 * 60
        when 'days', 'day'
          num * 60 * 60 * 24
        when 'weeks', 'week'
          num * 60 * 60 * 24 * 7
        else
          raise "Unknown time unit '#{units}' in '#{r}"
        end
    end
    v.send(@op, r)
  end
end
