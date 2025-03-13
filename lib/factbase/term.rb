# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'backtrace'
require_relative '../factbase'
require_relative 'fact'
require_relative 'tee'

# Term.
#
# This is an internal class, it is not supposed to be instantiated directly.
#
# It is possible to use for testing directly, for example to make a
# term with two arguments:
#
#  require 'factbase/fact'
#  require 'factbase/term'
#  f = Factbase::Fact.new({ 'foo' => [42, 256, 'Hello, world!'] })
#  t = Factbase::Term.new(:lt, [:foo, 50])
#  assert(t.evaluate(f))
#
# The design of this class may look ugly, since it has a large number of
# methods, each of which corresponds to a different type of a +Term+. A much
# better design would definitely involve many classes, one per each type
# of a term. It's not done this way because of an experimental nature of
# the project. Most probably we should keep current design intact, since it
# works well and is rather simple to extend (by adding new term types).
# Moreover, it looks like the number of possible term types is rather limited
# and currently we implement most of them.
#
# It is NOT thread-safe!
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Term
  # The operator of this term
  # @return [Symbol] The operator
  attr_reader :op

  # The operands of this term
  # @return [Array] The operands
  attr_reader :operands

  require_relative 'terms/math'
  include Factbase::Math

  require_relative 'terms/logical'
  include Factbase::Logical

  require_relative 'terms/aggregates'
  include Factbase::Aggregates

  require_relative 'terms/strings'
  include Factbase::Strings

  require_relative 'terms/casting'
  include Factbase::Casting

  require_relative 'terms/meta'
  include Factbase::Meta

  require_relative 'terms/aliases'
  include Factbase::Aliases

  require_relative 'terms/ordering'
  include Factbase::Ordering

  require_relative 'terms/defn'
  include Factbase::Defn

  require_relative 'terms/system'
  include Factbase::System

  require_relative 'terms/debug'
  include Factbase::Debug

  # Ctor.
  # @param [Symbol] operator Operator
  # @param [Array] operands Operands
  def initialize(operator, operands)
    @op = operator
    @operands = operands
  end

  def redress!(type, **args)
    extend type
    args.each { |k, v| send(:instance_variable_set, :"@#{k}", v) }
    @operands.map do |op|
      if op.is_a?(Factbase::Term)
        op.redress!(type, **args)
      else
        op
      end
    end
  end

  # Try to predict which facts from the provided list
  # should be evaluated. If no prediction can be made,
  # the same list is returned.
  # @param [Array<Hash>] maps Records to iterate, maybe
  # @return [Array<Hash>] Records to iterate
  def predict(maps, _params)
    maps
  end

  # Does it match the fact?
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] TRUE if matches
  def evaluate(fact, maps, fb)
    send(@op, fact, maps, fb)
  rescue NoMethodError => e
    raise "Probably the term '#{@op}' is not defined at #{self}:\n#{Backtrace.new(e)}"
  rescue StandardError => e
    raise "#{e.message} at #{self}:\n#{Backtrace.new(e)}"
  end

  # Simplify it if possible.
  # @return [Factbase::Term] New term or itself
  def simplify
    m = "#{@op}_simplify"
    if respond_to?(m, true)
      send(m)
    else
      self
    end
  end

  # Does it have any dependencies on a fact?
  #
  # If a term is static, it will return the same value for +evaluate+,
  # no matter what is the fact given.
  #
  # @return [Boolean] TRUE if static
  def static?
    return true if @op == :agg
    @operands.each do |o|
      return false if o.is_a?(Factbase::Term) && !o.static?
      return false if o.is_a?(Symbol) && !o.to_s.start_with?('$')
    end
    true
  end

  # Does it have any variables (+$foo+, for example) inside?
  #
  # @return [Boolean] TRUE if abstract
  def abstract?
    @operands.each do |o|
      return true if o.is_a?(Factbase::Term) && o.abstract?
      return true if o.is_a?(Symbol) && o.to_s.start_with?('$')
    end
    false
  end

  # Turns it into a string.
  # @return [String] The string of it
  def to_s
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

  def at(fact, maps, fb)
    assert_args(2)
    i = _values(0, fact, maps, fb)
    raise "Too many values (#{i.size}) at first position, one expected" unless i.size == 1
    i = i[0]
    return nil if i.nil?
    v = _values(1, fact, maps, fb)
    return nil if v.nil?
    v[i]
  end

  private

  def assert_args(num)
    c = @operands.size
    raise "Too many (#{c}) operands for '#{@op}' (#{num} expected)" if c > num
    raise "Too few (#{c}) operands for '#{@op}' (#{num} expected)" if c < num
  end

  def _by_symbol(pos, fact)
    o = @operands[pos]
    raise "A symbol expected at ##{pos}, but '#{o}' (#{o.class}) provided" unless o.is_a?(Symbol)
    k = o.to_s
    fact[k]
  end

  # @return [Array|nil] Either array of values or NIL
  def _values(pos, fact, maps, fb)
    v = @operands[pos]
    v = v.evaluate(fact, maps, fb) if v.is_a?(Factbase::Term)
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
    v
  end
end
