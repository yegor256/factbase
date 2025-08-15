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
    @uniques = {} if @uniques.nil?
    raise "Too few operands for 'unique' (at least 1 expected)" if @operands.empty?
    results = []
    @operands.each_with_index do |_, i|
      @uniques[i] = [] if @uniques[i].nil?
      vv = _values(i, fact, maps, fb)
      return false if vv.nil?
      vv = [vv] unless vv.respond_to?(:to_a)
      vv.each do |v|
        if @uniques[i].include?(v)
          results << false
        else
          @uniques[i] << v
          results << true
        end
      end
    end
    return false if results.all?(false)
    true
  end
end
