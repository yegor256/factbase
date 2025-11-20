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
end
