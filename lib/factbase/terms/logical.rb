# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Logical terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Logical
  # Always returns true, regardless of the fact
  # @param [Factbase::Fact] _fact The fact (unused)
  # @param [Array<Factbase::Fact>] _maps All maps available (unused)
  # @return [Boolean] Always returns true
  def always(_fact, _maps, _fb)
    assert_args(0)
    true
  end

  # Always returns false, regardless of the fact
  # @param [Factbase::Fact] _fact The fact (unused)
  # @param [Array<Factbase::Fact>] _maps All maps available (unused)
  # @return [Boolean] Always returns false
  def never(_fact, _maps, _fb)
    assert_args(0)
    false
  end

  # Logical negation (NOT) of an operand
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @return [Boolean] Negated boolean result of the operand
  def not(fact, maps, fb)
    assert_args(1)
    !_only_bool(_values(0, fact, maps, fb), 0)
  end

  # Logical OR of multiple operands
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @return [Boolean] True if any operand evaluates to true, false otherwise
  def or(fact, maps, fb)
    (0..(@operands.size - 1)).each do |i|
      return true if _only_bool(_values(i, fact, maps, fb), i)
    end
    false
  end

  # Logical AND of multiple operands
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @return [Boolean] True if all operands evaluate to true, false otherwise
  def and(fact, maps, fb)
    (0..(@operands.size - 1)).each do |i|
      return false unless _only_bool(_values(i, fact, maps, fb), i)
    end
    true
  end

  # Logical implication (IF...THEN)
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @return [Boolean] True if first operand is false OR both are true
  def when(fact, maps, fb)
    assert_args(2)
    a = @operands[0]
    b = @operands[1]
    !a.evaluate(fact, maps, fb) || (a.evaluate(fact, maps, fb) && b.evaluate(fact, maps, fb))
  end

  # Returns the first non-nil value or the second value
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @return [Object] First operand if not nil, otherwise second operand
  def either(fact, maps, fb)
    assert_args(2)
    v = _values(0, fact, maps, fb)
    return v unless v.nil?
    _values(1, fact, maps, fb)
  end

  # Simplifies AND or OR expressions by removing duplicates
  # @return [Factbase::Term] Simplified term
  def and_or_simplify
    strs = []
    ops = []
    @operands.each do |o|
      o = o.simplify
      s = o.to_s
      next if strs.include?(s)
      strs << s
      ops << o
    end
    return ops[0] if ops.size == 1
    self.class.new(@op, ops)
  end

  # Simplifies AND expressions by removing duplicates
  # @return [Factbase::Term] Simplified term
  def and_simplify
    and_or_simplify
  end

  # Simplifies OR expressions by removing duplicates
  # @return [Factbase::Term] Simplified term
  def or_simplify
    and_or_simplify
  end

  # Helper method to ensure a value is boolean
  # @param [Object] val The value to check
  # @param [Integer] pos The position of the operand
  # @return [Boolean] The boolean value
  # @raise [RuntimeError] If value is not a boolean
  def _only_bool(val, pos)
    val = val[0] if val.respond_to?(:each)
    return false if val.nil?
    return val if val.is_a?(TrueClass) || val.is_a?(FalseClass)
    raise "Boolean expected, while #{val.class} received from #{@operands[pos]}"
  end
end
