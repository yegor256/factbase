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
