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
#  f = Factbase::Fact.new(Mutex.new, { 'foo' => [42, 256, 'Hello, world!'] })
#  t = Factbase::Term.new(Factbase.new, :lt, [:foo, 50])
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
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Term
  attr_reader :op, :operands

  require_relative 'terms/math'
  include Factbase::Term::Math

  require_relative 'terms/logical'
  include Factbase::Term::Logical

  require_relative 'terms/aggregates'
  include Factbase::Term::Aggregates

  require_relative 'terms/strings'
  include Factbase::Term::Strings

  require_relative 'terms/casting'
  include Factbase::Term::Casting

  require_relative 'terms/meta'
  include Factbase::Term::Meta

  require_relative 'terms/aliases'
  include Factbase::Term::Aliases

  require_relative 'terms/ordering'
  include Factbase::Term::Ordering

  require_relative 'terms/defn'
  include Factbase::Term::Defn

  require_relative 'terms/system'
  include Factbase::Term::System

  require_relative 'terms/debug'
  include Factbase::Term::Debug

  # Ctor.
  # @param [Symbol] operator Operator
  # @param [Array] operands Operands
  def initialize(operator, operands)
    @op = operator
    @operands = operands
  end

  # Does it match the fact?
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @return [bool] TRUE if matches
  def evaluate(fact, maps)
    send(@op, fact, maps)
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

  private

  def at(fact, maps)
    assert_args(2)
    i = the_values(0, fact, maps)
    raise "Too many values (#{i.size}) at first position, one expected" unless i.size == 1
    i = i[0]
    return nil if i.nil?
    v = the_values(1, fact, maps)
    return nil if v.nil?
    v[i]
  end

  def assert_args(num)
    c = @operands.size
    raise "Too many (#{c}) operands for '#{@op}' (#{num} expected)" if c > num
    raise "Too few (#{c}) operands for '#{@op}' (#{num} expected)" if c < num
  end

  def by_symbol(pos, fact)
    o = @operands[pos]
    raise "A symbol expected at ##{pos}, but '#{o}' (#{o.class}) provided" unless o.is_a?(Symbol)
    k = o.to_s
    fact[k]
  end

  # @return [Array|nil] Either array of values or NIL
  def the_values(pos, fact, maps)
    v = @operands[pos]
    v = v.evaluate(fact, maps) if v.is_a?(Factbase::Term)
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
