# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require 'others'
require_relative '../factbase'
require_relative '../factbase/syntax'

# A decorator of a Factbase, that checks rules on every set.
#
# Say, you want every fact to have +foo+ property. You want any attempt
# to insert a fact without this property to lead to a runtime error. Here is how:
#
#  fb = Factbase.new
#  fb = Factabase::Rules.new(fb, '(exists foo)')
#  fb.txn do |fbt|
#    f = fbt.insert
#    f.bar = 3 # No exception here
#  end # Runtime exception here (transaction won't commit)
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Rules
  decoor(:fb)

  def initialize(fb, rules, check = Check.new(rules), uid: nil)
    raise 'The "fb" is nil' if fb.nil?
    @fb = fb
    raise 'The "rules" is nil' if rules.nil?
    @rules = rules
    raise 'The "check" is nil' if check.nil?
    @check = check
    @uid = uid
  end

  def insert
    Fact.new(@fb.insert, @check, @fb)
  end

  def query(query, maps = nil)
    Query.new(@fb.query(query, maps), @check, @fb)
  end

  def txn
    before = @check
    later = Later.new(@uid)
    @check = later
    @fb.txn do |fbt|
      yield Factbase::Rules.new(fbt, @rules, @check, uid: @uid)
      @check = before
      fbt.query('(always)').each do |f|
        next unless later.include?(f)
        @check.it(f, @fb)
      end
    end
  end

  # Fact decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  #
  class Fact
    def initialize(fact, check, fb)
      @fact = fact
      @check = check
      @fb = fb
    end

    def to_s
      @fact.to_s
    end

    def all_properties
      @fact.all_properties
    end

    others do |*args|
      r = @fact.method_missing(*args)
      k = args[0].to_s
      @check.it(@fact, @fb) if k.end_with?('=')
      r
    end
  end

  # Query decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  class Query
    decoor(:query)

    def initialize(query, check, fb)
      @query = query
      @check = check
      @fb = fb
    end

    def each(fb = @fb, params = {})
      return to_enum(__method__, fb, params) unless block_given?
      @query.each(fb, params) do |f|
        yield Fact.new(f, @check, fb)
      end
    end
  end

  # Check one fact.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  class Check
    def initialize(expr)
      @expr = expr
    end

    def it(fact, fb)
      return if Factbase::Syntax.new(@expr).to_term.evaluate(fact, [], fb)
      e = "#{@expr[0..32]}..." if @expr.length > 32
      raise "The fact doesn't match the #{e.inspect} rule: #{fact}"
    end
  end

  # Check one fact (never complaining).
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  class Later
    def initialize(uid)
      @uid = uid
      @facts = Set.new
    end

    def it(fact, _fb)
      a = fact[@uid]
      return if a.nil?
      @facts << a[0] unless @uid.nil?
    end

    def include?(fact)
      return true if @uid.nil?
      a = fact[@uid]
      return true if a.nil?
      @facts.include?(a[0])
    end
  end
end
