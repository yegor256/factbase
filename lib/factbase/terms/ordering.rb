# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Ordering terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Ordering
  def prev(fact, maps, fb)
    assert_args(1)
    before = @prev
    v = _values(0, fact, maps, fb)
    @prev = v
    before
  end

  def unique(fact, maps, fb)
    @seen = Set.new if @seen.nil?
    raise "Too few operands for 'unique' (at least 1 expected)" if @operands.empty?
    vv = (0..(@operands.size - 1)).map { |i| _values(i, fact, maps, fb) }
    return false if vv.any?(nil)
    pass = true
    _cartesian(vv).each do |t|
      pass = false if @seen.include?(t)
      @seen << t
    end
    pass
  end

  private

  # Multiplies arrays and returns a list of all possible combinations
  # of their elements. If this array is provided:
  #
  #  [ [4, 3], [2, 88, 13] ]
  #
  # This will be the result:
  #
  # [ [4, 2], [4, 88], [4, 13], [3, 2], [3, 88], [3, 13]]
  def _cartesian(vv)
    ff = vv.first.zip
    if vv.one?
      ff
    else
      tail = _cartesian(vv[1..])
      ff.map { |f| tail.map { |t| f + t } }
    end
  end
end
