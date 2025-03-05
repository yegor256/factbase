# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'json'
require 'time'
require 'others'
require_relative '../factbase'

# A single fact in a factbase.
#
# This is an internal class, it is not supposed to be instantiated directly,
# by the +Factbase+ class.
# However, it is possible to use it for testing directly, for example to make a
# fact with a single key/value pair inside:
#
#  require 'factbase/fact'
#  f = Factbase::Fact.new({ 'foo' => [42, 256, 'Hello, world!'] })
#  assert_equal(42, f.foo)
#
# A fact is basically a key/value hash map, where values are non-empty
# sets of values.
#
# It is NOT thread-safe!
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Fact
  # Ctor.
  # @param [Hash] map A map of key/value pairs
  def initialize(map)
    @map = map
  end

  # Convert it to a string.
  # @return [String] String representation of it (in JSON)
  def to_s
    "[ #{@map.map { |k, v| "#{k}: #{v}" }.join(', ')} ]"
  end

  # Get a list of all props.
  # @return [Array<String>] List of all props in the fact
  def all_properties
    @map.keys
  end

  # When a method is missing, this method is called.
  others do |*args|
    k = args[0].to_s
    if k.end_with?('=')
      kk = k[0..-2]
      raise "Invalid prop name '#{kk}'" unless kk.match?(/^[a-z_][_a-zA-Z0-9]*$/)
      raise "Prohibited prop name '#{kk}'" if methods.include?(kk.to_sym)
      v = args[1]
      raise "The value of '#{kk}' can't be nil" if v.nil?
      raise "The value of '#{kk}' can't be empty" if v == ''
      raise "The type '#{v.class}' of '#{kk}' is not allowed" unless [String, Integer, Float, Time].include?(v.class)
      v = v.utc if v.is_a?(Time)
      @map[kk] = [] if @map[kk].nil?
      @map[kk] << v
      @map[kk].uniq!
      nil
    elsif k == '[]'
      @map[args[1].to_s]
    else
      v = @map[k]
      if v.nil?
        raise "Can't get '#{k}', the fact is empty" if @map.empty?
        raise "Can't find '#{k}' attribute out of [#{@map.keys.join(', ')}]"
      end
      v[0]
    end
  end
end
