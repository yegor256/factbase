# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Aggregating terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Aggregates
  def min(_fact, maps, _fb)
    assert_args(1)
    _best(maps) { |v, b| v < b }
  end

  def max(_fact, maps, _fb)
    assert_args(1)
    _best(maps) { |v, b| v > b }
  end

  def count(_fact, maps, _fb)
    maps.size
  end

  def nth(_fact, maps, _fb)
    assert_args(2)
    pos = @operands[0]
    raise "An integer is expected, but #{pos} provided" unless pos.is_a?(Integer)
    k = @operands[1]
    raise "A symbol is expected, but #{k} provided" unless k.is_a?(Symbol)
    m = maps[pos]
    return nil if m.nil?
    m[k.to_s]
  end

  def first(_fact, maps, _fb)
    assert_args(1)
    k = @operands[0]
    raise "A symbol is expected, but #{k} provided" unless k.is_a?(Symbol)
    first = maps[0]
    return nil if first.nil?
    first[k.to_s]
  end

  def sum(_fact, maps, _fb)
    k = @operands[0]
    raise "A symbol is expected, but '#{k}' provided" unless k.is_a?(Symbol)
    sum = 0
    maps.each do |m|
      vv = m[k.to_s]
      next if vv.nil?
      vv = [vv] unless vv.respond_to?(:to_a)
      vv.each do |v|
        sum += v
      end
    end
    sum
  end

  def agg(fact, maps, fb)
    assert_args(2)
    selector = @operands[0]
    raise "A term is expected, but '#{selector}' provided" unless selector.is_a?(Factbase::Term)
    term = @operands[1]
    raise "A term is expected, but '#{term}' provided" unless term.is_a?(Factbase::Term)
    subset = fb.query(selector, maps).each(fb, fact).to_a
    term.evaluate(nil, subset, fb)
  end

  def empty(fact, maps, fb)
    assert_args(1)
    term = @operands[0]
    raise "A term is expected, but '#{term}' provided" unless term.is_a?(Factbase::Term)
    # rubocop:disable Lint/UnreachableLoop
    fb.query(term, maps).each(fb, fact) do
      return false
    end
    # rubocop:enable Lint/UnreachableLoop
    true
  end

  def _best(maps)
    k = @operands[0]
    raise "A symbol is expected, but #{k} provided" unless k.is_a?(Symbol)
    best = nil
    maps.each do |m|
      vv = m[k.to_s]
      next if vv.nil?
      vv = [vv] unless vv.respond_to?(:to_a)
      vv.each do |v|
        best = v if best.nil? || yield(v, best)
      end
    end
    best
  end
end
