# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'
require 'set'

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

  def unique(fact, maps)
    @uniques = Set.new if @uniques.nil?
    assert_args(1)
    vv = _values(0, fact, maps)
    return false if vv.nil?
    vv = [vv] unless vv.respond_to?(:to_a)
    vv.each do |v|
      return false if @uniques.include?(v)
      @uniques << v
    end
    true
  end
end
