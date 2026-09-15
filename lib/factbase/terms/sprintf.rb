# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# Format term.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Sprintf < Factbase::TermBase
  def initialize(operands)
    super()
    @operands = operands
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [String] The formatted string
  def evaluate(fact, maps, fb)
    fmt = only(0, fact, maps, fb)
    if fmt.nil?
      raise(ArgumentError, "The format of 'sprintf' is #{@operands[0].inspect}, which the fact doesn't have")
    end
    formatted(fmt, (1..(@operands.length - 1)).map { |i| only(i, fact, maps, fb) })
  end

  private

  # Read one value at the given position, refusing a property that has more.
  # @param [Integer] pos The position of the operand
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Object] The only value at this position
  def only(pos, fact, maps, fb)
    vv = _values(pos, fact, maps, fb)
    return if vv.nil?
    raise(ArgumentError, "Too many values at position #{pos}, one expected") unless vv.size == 1
    vv[0]
  end

  def formatted(fmt, ops)
    format(*([fmt] + ops))
  rescue ArgumentError, TypeError => e
    raise(RuntimeError, "Cannot format #{ops.inspect} with '#{fmt}' in (sprintf ...): #{e.message}")
  end
end
