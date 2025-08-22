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
    Enumerator.product(*vv).to_a.each do |t|
      pass = false if @seen.include?(t)
      @seen << t
    end
    pass
  end
end
