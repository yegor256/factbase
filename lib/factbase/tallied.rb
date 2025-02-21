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

  def dup
    Factbase::Tallied.new(@fb.dup, @churn.dup)
  end

  def insert
    f = Fact.new(@fb.insert, @churn)
    @churn.append(1, 0, 0)
    f
  end

  def query(query)
    Query.new(@fb.query(query), @churn)
  end

  def txn(this = self, &)
    @fb.txn(this) do |fbt|
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

    decoor(:fact)

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
    def initialize(query, churn)
      @query = query
      @churn = churn
    end

    def one(params = {})
      @query.one(params)
    end

    def each(params = {}, &)
      @query.each(params) do |f|
        yield Fact.new(f, @churn)
      end
    end

    def delete!
      c = @query.delete!
      @churn.append(0, c, 0)
      c
    end
  end
end
