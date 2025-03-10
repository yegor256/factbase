# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require 'others'
require_relative '../factbase'
require_relative 'churn'

# A decorator of a Factbase, that count all operations and then returns
# an instance of Factbase::Churn.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Tallied
  attr_reader :churn

  def initialize(fb, churn = Factbase::Churn.new)
    raise 'The "fb" is nil' if fb.nil?
    @fb = fb
    @churn = churn
  end

  decoor(:fb)

  def insert
    f = Fact.new(@fb.insert, @churn)
    @churn.append(1, 0, 0)
    f
  end

  def query(query)
    Query.new(@fb.query(query), @churn, @fb)
  end

  def txn
    @fb.txn do |fbt|
      yield Factbase::Tallied.new(fbt, @churn)
    end
  end

  # Fact decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  class Fact
    def initialize(fact, churn)
      @fact = fact
      @churn = churn
    end

    def to_s
      @fact.to_s
    end

    def all_properties
      @fact.all_properties
    end

    others do |*args|
      r = @fact.method_missing(*args)
      @churn.append(0, 0, 1) if args[0].to_s.end_with?('=')
      r
    end
  end

  # Query decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  class Query
    def initialize(query, churn, fb)
      @query = query
      @churn = churn
      @fb = fb
    end

    def one(fb = @fb, params = {})
      @query.one(fb, params)
    end

    def each(fb = @fb, params = {}, &)
      return to_enum(__method__, fb, params) unless block_given?
      @query.each(fb, params) do |f|
        yield Fact.new(f, @churn)
      end
    end

    def delete!(fb = @fb)
      c = @query.delete!(fb)
      @churn.append(0, c, 0)
      c
    end
  end
end
