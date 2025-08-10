# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'others'
require 'decoor'
require_relative '../factbase'

# A decorator of a Factbase, that checks invariants on every set.
#
# For example, you can use this decorator if you want to check that every
# fact has +when+:
#
#  fb = Factbase::Inv.new(Factbase.new) do |f, fbt|
#    assert !f['when'].nil?
#  end
#
# The second argument passed to the block is the factbase, while the first
# one is the fact just touched.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Inv
  decoor(:fb)

  def initialize(fb, &block)
    @fb = fb
    @block = block
  end

  def insert
    Fact.new(@fb.insert, @block)
  end

  def query(query, maps = nil)
    Query.new(@fb.query(query, maps), @block, self)
  end

  def txn
    @fb.txn do |fbt|
      yield Factbase::Inv.new(fbt, &@block)
    end
  end

  # Fact decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  #
  class Fact
    def initialize(fact, block)
      @fact = fact
      @block = block
    end

    def to_s
      @fact.to_s
    end

    def all_properties
      @fact.all_properties
    end

    others do |*args|
      k = args[0].to_s
      @block.call(k[0..-2], args[1]) if k.end_with?('=')
      @fact.method_missing(*args)
    end
  end

  # Query decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  #
  class Query
    decoor(:query)

    def initialize(query, block, fb)
      @query = query
      @block = block
      @fb = fb
    end

    def to_s
      @query.to_s
    end

    def each(fb = @fb, params = {})
      return to_enum(__method__, fb, params) unless block_given?
      @query.each(fb, params) do |f|
        yield Fact.new(f, @block)
      end
    end
  end
end
