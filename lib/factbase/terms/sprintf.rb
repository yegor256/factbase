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
    raise(ArgumentError, "Too few operands for 'sprintf' (at least 1 expected)") if @operands.empty?
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
    format(*([fmt] + decimal(fmt, ops)))
  rescue ArgumentError, KeyError, TypeError, RangeError => e
    raise(RuntimeError, "Cannot format #{ops.inspect} with '#{fmt}' in (sprintf ...): #{e.message}")
  end

  # Reads as decimal the strings that go to an integer directive.
  #
  # Ruby's +format+ reads such a string with base detection, so '010' becomes 8
  # and '0x1A' becomes 26, while +to_integer+ reads both as decimal only.
  #
  # @param [String] fmt The format
  # @param [Array] ops The arguments
  # @return [Array] The arguments, with such strings turned into integers
  def decimal(fmt, ops)
    ops = ops.dup
    seq = 0
    fmt.scan(/%(?:%|(?:(\d+)\$)?[-+ 0#]*(\*)?\d*(?:\.(\*)?\d*)?([a-zA-Z]))/) do |pos, width, prec, type|
      next if type.nil?
      seq += 1 if width
      seq += 1 if prec
      i = pos.nil? ? seq : Integer(pos, 10) - 1
      seq += 1 if pos.nil?
      ops[i] = Integer(ops[i], 10) if 'diubBoxX'.include?(type) && ops[i].is_a?(String)
    end
    ops
  end
end
