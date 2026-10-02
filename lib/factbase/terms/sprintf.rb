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
    fmt = _values(0, fact, maps, fb)&.first
    if fmt.nil?
      raise(ArgumentError, "The format of 'sprintf' is #{@operands[0].inspect}, which the fact doesn't have")
    end
    formatted(fmt, (1..(@operands.length - 1)).map { |i| argument(i, fmt, fact, maps, fb) })
  end

  private

  def argument(pos, fmt, fact, maps, fb)
    value = _values(pos, fact, maps, fb)&.first
    if value.nil?
      raise(ArgumentError, "The operand #{@operands[pos].inspect} of 'sprintf' with '#{fmt}' is absent in the fact")
    end
    value
  end

  def formatted(fmt, ops)
    format(*([fmt] + ops))
  rescue ArgumentError, KeyError, TypeError => e
    raise(RuntimeError, "Cannot format #{ops.inspect} with '#{fmt}' in (sprintf ...): #{e.message}")
  end
end
