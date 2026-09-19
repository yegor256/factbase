# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Base class for all terms.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::TermBase
  # Set the name the user used for this term and its implementation helpers.
  # @param [Symbol] name Name of the term in the query
  # rubocop:disable Elegant/GoodMethodName
  def name=(name)
    @name = name
    instance_variables.each do |variable|
      value = instance_variable_get(variable)
      value.name = name if value.is_a?(Factbase::TermBase)
    end
  end
  # rubocop:enable Elegant/GoodMethodName

  # Turns it into a string.
  # @return [String] The string of it
  def to_s
    @to_s ||=
      begin
        items = []
        items << @op
        items +=
          @operands.map do |o|
            if o.is_a?(String)
              "'#{o.gsub("'", "\\\\'").gsub('"', '\\\\"')}'"
            elsif o.is_a?(Time)
              o.utc.iso8601
            else
              o.to_s
            end
          end
        "(#{items.join(' ')})"
      end
  end

  private

  def assert_args(num)
    c = @operands.size
    name = @name || @op
    raise(ArgumentError, "Too many (#{c}) operands for '#{name}' (#{num} expected)") if c > num
    raise(ArgumentError, "Too few (#{c}) operands for '#{name}' (#{num} expected)") if c < num
  end

  # Turns facts into plain maps, keeping only the properties they really carry.
  #
  # A fact coming out of a query is a +Factbase::Tee+, whose +all_properties+
  # also lists the names of the query parameters. Reading such a name back gives
  # NIL, which is not a value any property may have.
  #
  # @param [Array<Factbase::Fact>] facts The facts to turn into maps
  # @return [Array<Hash>] The maps
  def _flatten(facts)
    facts.map do |f|
      f.all_properties.each_with_object({}) do |k, h|
        v = f[k]
        h[k] = v unless v.nil?
      end
    end
  end

  def _by_symbol(pos, fact)
    o = @operands[pos]
    raise(ArgumentError, "A symbol expected at ##{pos}, but '#{o}' (#{o.class}) provided") unless o.is_a?(Symbol)
    fact[o.to_s]
  end

  # @return [Array|nil] Either array of values or NIL
  def _values(pos, fact, maps, fb)
    v = @operands[pos]
    v = v.evaluate(fact, maps, fb) if v.is_a?(Factbase::Term)
    v = v.evaluate(fact, maps, fb) if v.is_a?(Factbase::TermBase)
    v = fact[v.to_s] if v.is_a?(Symbol)
    return v if v.nil?
    unless v.is_a?(Array)
      v =
        if v.respond_to?(:each)
          v.to_a
        else
          [v]
        end
    end
    raise(ArgumentError, 'Why not array?') unless v.is_a?(Array)
    unless v.all? { |i| [Float, Integer, String, Time, TrueClass, FalseClass].any? { |t| i.is_a?(t) } }
      raise(ArgumentError, 'Wrong type inside')
    end
    v
  end

  # Extract the parameters made available to an inner query: the parameters of
  # the outer query first, then the properties of the outer fact.
  # @param [Factbase::Fact] fact The fact being evaluated
  # @return [Hash] Parameters indexed by their names
  def params(fact)
    Context.new(fact, fact.all_properties.to_h { |name| [name, fact["$#{name}"]] }.compact)
  end

  # Values available to the selector of an aggregation.
  class Context
    # Ctor.
    # @param [Factbase::Fact] fact The outer fact
    # @param [Hash] params Parameters of the outer query
    def initialize(fact, params)
      @fact = fact
      @params = params
    end

    # Get a parameter, or the property of the outer fact when it is not a parameter.
    # @param [String] name Parameter or property name
    # @return [Object] The value
    def [](name)
      @params.fetch(name) { @fact[name] }
    end

    # List all available names.
    # @return [Array<String>] Names of the parameters and fact properties
    def all_properties
      @fact.all_properties | @params.keys
    end
  end
end
