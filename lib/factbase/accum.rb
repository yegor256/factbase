# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'others'
require_relative '../factbase'

# Accumulator of props, a decorator of +Factbase::Fact+.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Accum
  # Ctor.
  # @param [Factbase::Fact] fact The fact to decorate
  # @param [Hash] props Hash of props that were set
  # @param [Boolean] pass TRUE if all "set" operations must go through, to the +fact+
  def initialize(fact, props, pass)
    @fact = fact
    @props = props
    @pass = pass
  end

  def to_s
    "#{@fact} + #{@props}"
  end

  def all_properties
    @fact.all_properties
  end

  others do |*args|
    k = args[0].to_s
    if k.end_with?('=')
      kk = k[0..-2]
      @props[kk] = [] if @props[kk].nil?
      @props[kk] << args[1]
      @fact.method_missing(*args) if @pass
    elsif k == '[]'
      kk = args[1].to_s
      vv = @props[kk].nil? ? [] : @props[kk]
      vvv = @fact.method_missing(*args)
      vvv = [vvv] unless vvv.nil? || vvv.is_a?(Array)
      vv += vvv unless vvv.nil?
      vv.uniq!
      vv.empty? ? nil : vv
    elsif @props[k].nil?
      @fact.method_missing(*args)
    else
      @props[k][0]
    end
  end
end
