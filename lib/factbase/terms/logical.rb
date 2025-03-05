# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Logical terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Term::Logical
  def always(_fact, _maps)
    assert_args(0)
    true
  end

  def never(_fact, _maps)
    assert_args(0)
    false
  end

  def not(fact, maps)
    assert_args(1)
    !_only_bool(the_values(0, fact, maps), 0)
  end

  def or(fact, maps)
    (0..@operands.size - 1).each do |i|
      return true if _only_bool(the_values(i, fact, maps), i)
    end
    false
  end

  def and(fact, maps)
    (0..@operands.size - 1).each do |i|
      return false unless _only_bool(the_values(i, fact, maps), i)
    end
    true
  end

  def when(fact, maps)
    assert_args(2)
    a = @operands[0]
    b = @operands[1]
    !a.evaluate(fact, maps) || (a.evaluate(fact, maps) && b.evaluate(fact, maps))
  end

  def either(fact, maps)
    assert_args(2)
    v = the_values(0, fact, maps)
    return v unless v.nil?
    the_values(1, fact, maps)
  end

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
    Factbase::Term.new(@op, ops)
  end

  def and_simplify
    and_or_simplify
  end

  def or_simplify
    and_or_simplify
  end

  def _only_bool(val, pos)
    val = val[0] if val.respond_to?(:each)
    return false if val.nil?
    return val if val.is_a?(TrueClass) || val.is_a?(FalseClass)
    raise "Boolean expected, while #{val.class} received from #{@operands[pos]}"
  end
end
