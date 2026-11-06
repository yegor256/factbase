# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'others'
require_relative '../factbase'

# Tee of two facts.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Tee
  # Ctor.
  # @param [Factbase::Fact] fact Primary fact to use for reading
  # @param [Factbase::Fact] upper Fact to access with a "$" prefix
  def initialize(fact, upper)
    raise(ArgumentError, 'Fact is nil') if fact.nil?
    @fact = fact
    raise(ArgumentError, 'Upper is nil') if upper.nil?
    @upper = upper
  end

  def to_s
    @fact.to_s
  end

  def all_properties
    (@fact.is_a?(Hash) ? @fact.keys : @fact.all_properties) |
      (@upper.is_a?(Hash) ? @upper.keys : @upper.all_properties)
  end

  # The value of a parameter of the query, and nothing else.
  #
  # A property of the upper fact is not a parameter of the query. A nested
  # aggregation asks this to find out which names it may pass down as
  # parameters of its own.
  #
  # @param [String] name The name of the parameter, with no "$" in front
  # @return [Object, nil] The value, or NIL if there is no such parameter
  def query_parameter(name)
    return @upper.query_parameter(name) if @upper.respond_to?(:query_parameter)
    @upper[name]
  end

  others do |*args|
    if args[0].to_s == '[]' && args[1].start_with?('$')
      n = args[1].to_s
      n = n[1..] unless @upper.is_a?(Factbase::Tee)
      r = @upper[n]
      r = [r] unless r.respond_to?(:each) || r.nil?
      r
    else
      @fact.public_send(*args)
    end
  end
end
