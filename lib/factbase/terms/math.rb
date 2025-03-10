# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Math terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Term::Math
  def plus(fact, maps, fb)
    _arithmetic(:+, fact, maps)
  end

  def minus(fact, maps, fb)
    _arithmetic(:-, fact, maps)
  end

  def times(fact, maps, fb)
    _arithmetic(:*, fact, maps)
  end

  def div(fact, maps, fb)
    _arithmetic(:/, fact, maps)
  end

  def zero(fact, maps, fb)
    assert_args(1)
    vv = _values(0, fact, maps)
    return false if vv.nil?
    vv.any? { |v| (v.is_a?(Integer) || v.is_a?(Float)) && v.zero? }
  end

  def eq(fact, maps, fb)
    _cmp(:==, fact, maps)
  end

  def lt(fact, maps, fb)
    _cmp(:<, fact, maps)
  end

  def gt(fact, maps, fb)
    _cmp(:>, fact, maps)
  end

  def lte(fact, maps, fb)
    _cmp(:<=, fact, maps)
  end

  def gte(fact, maps, fb)
    _cmp(:>=, fact, maps)
  end

  def _cmp(op, fact, maps)
    assert_args(2)
    lefts = _values(0, fact, maps)
    return false if lefts.nil?
    rights = _values(1, fact, maps)
    return false if rights.nil?
    lefts.any? do |l|
      l = l.floor if l.is_a?(Time) && op == :==
      rights.any? do |r|
        r = r.floor if r.is_a?(Time) && op == :==
        l.send(op, r)
      end
    end
  end

  def _arithmetic(op, fact, maps)
    assert_args(2)
    lefts = _values(0, fact, maps)
    return nil if lefts.nil?
    raise 'Too many values at first position, one expected' unless lefts.size == 1
    rights = _values(1, fact, maps)
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
    v.send(op, r)
  end
end
