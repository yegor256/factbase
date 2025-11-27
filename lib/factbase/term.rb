# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'backtrace'
require_relative '../factbase'
require_relative 'fact'
require_relative 'tee'
require_relative 'terms/unique'
require_relative 'terms/prev'
require_relative 'terms/concat'
require_relative 'terms/sprintf'
require_relative 'terms/matches'
require_relative 'terms/traced'
require_relative 'terms/assert'
require_relative 'terms/env'
require_relative 'terms/defn'
require_relative 'terms/undef'
require_relative 'terms/as'
require_relative 'terms/join'
require_relative 'terms/exists'
require_relative 'terms/absent'
require_relative 'terms/size'
require_relative 'terms/type'
require_relative 'terms/nil'
require_relative 'terms/many'
require_relative 'terms/one'
require_relative 'terms/to_string'
require_relative 'terms/to_integer'
require_relative 'terms/to_float'
require_relative 'terms/to_time'
require_relative 'terms/sorted'
require_relative 'terms/inverted'
require_relative 'terms/head'
require_relative 'terms/plus'
require_relative 'terms/minus'
require_relative 'terms/times'
require_relative 'terms/div'
require_relative 'terms/zero'
require_relative 'terms/eq'
require_relative 'terms/lt'
require_relative 'terms/lte'
require_relative 'terms/gt'
require_relative 'terms/gte'
require_relative 'terms/always'
require_relative 'terms/never'
require_relative 'terms/not'
require_relative 'terms/or'
require_relative 'terms/and'
require_relative 'terms/when'
require_relative 'terms/either'
require_relative 'terms/count'
require_relative 'terms/first'
require_relative 'terms/nth'
require_relative 'terms/sum'
require_relative 'terms/agg'

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

  require_relative 'terms/logical'
  include Factbase::Logical

  require_relative 'terms/aggregates'
  include Factbase::Aggregates

  require_relative 'terms/shared'
  include Factbase::TermShared

  # Ctor.
  # @param [Symbol] operator Operator
  # @param [Array] operands Operands
  def initialize(operator, operands)
    @op = operator
    @operands = operands
    @terms = {
      unique: Factbase::Unique.new(operands),
      prev: Factbase::Prev.new(operands),
      concat: Factbase::Concat.new(operands),
      sprintf: Factbase::Sprintf.new(operands),
      matches: Factbase::Matches.new(operands),
      traced: Factbase::Traced.new(operands),
      assert: Factbase::Assert.new(operands),
      env: Factbase::Env.new(operands),
      defn: Factbase::Defn.new(operands),
      undef: Factbase::Undef.new(operands),
      as: Factbase::As.new(operands),
      join: Factbase::Join.new(operands),
      exists: Factbase::Exists.new(operands),
      absent: Factbase::Absent.new(operands),
      size: Factbase::Size.new(operands),
      type: Factbase::Type.new(operands),
      nil: Factbase::Nil.new(operands),
      many: Factbase::Many.new(operands),
      one: Factbase::One.new(operands),
      to_string: Factbase::ToString.new(operands),
      to_integer: Factbase::ToInteger.new(operands),
      to_float: Factbase::ToFloat.new(operands),
      to_time: Factbase::ToTime.new(operands),
      sorted: Factbase::Sorted.new(operands),
      inverted: Factbase::Inverted.new(operands),
      head: Factbase::Head.new(operands),
      plus: Factbase::Plus.new(operands),
      minus: Factbase::Minus.new(operands),
      times: Factbase::Times.new(operands),
      div: Factbase::Div.new(operands),
      zero: Factbase::Zero.new(operands),
      eq: Factbase::Eq.new(operands),
      lt: Factbase::Lt.new(operands),
      lte: Factbase::Lte.new(operands),
      gt: Factbase::Gt.new(operands),
      gte: Factbase::Gte.new(operands),
      always: Factbase::Always.new(operands),
      never: Factbase::Never.new(operands),
      not: Factbase::Not.new(operands),
      or: Factbase::Or.new(operands),
      and: Factbase::And.new(operands),
      when: Factbase::When.new(operands),
      either: Factbase::Either.new(operands),
      count: Factbase::Count.new(operands),
      first: Factbase::First.new(operands),
      nth: Factbase::Nth.new(operands),
      sum: Factbase::Sum.new(operands),
      agg: Factbase::Agg.new(operands)
    }
  end

  # Extend it with the module.
  # @param [Module] type The type to extend with
  # @param [Hash] args Attributes to set
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
  # @param [Hash] params Params to use (keys must be strings, not symbols, with values as arrays)
  # @return [Array<Hash>] Records to iterate
  def predict(maps, fb, params)
    m = :"#{@op}_predict"
    if @terms.key?(@op)
      t = @terms[@op]
      if t.respond_to?(:predict)
        t.predict(maps, fb, params)
      else
        maps
      end
    elsif respond_to?(m)
      send(m, maps, fb, params)
    else
      maps
    end
  end

  # Evaluate term on a fact
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Object] The result of evaluation
  def evaluate(fact, maps, fb)
    if @terms.key?(@op)
      @terms[@op].evaluate(fact, maps, fb)
    else
      send(@op, fact, maps, fb)
    end
  rescue NoMethodError => e
    raise "Probably the term '#{@op}' is not defined at #{self}: #{e.message}"
  rescue StandardError => e
    raise "#{e.message.inspect} at #{self} at #{e.backtrace[0]}"
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
end
