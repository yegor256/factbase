# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require 'loog'
require_relative '../factbase'
require_relative 'enumerated'

# A decorator of a +Factbase+, that runs a provided block on every +insert+.
#
# For example, you can use this decorator if you want to put some properties
# into every fact that gets into the factbase:
#
#  fb = Factbase::Pre.new(Factbase.new) do |f, fbt|
#    f.when = Time.now
#  end
#
# The second argument passed to the block is the factbase, while the first
# one is the fact just inserted.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Pre
  decoor(:fb)
  include Factbase::Enumerated

  def initialize(fb, &block)
    raise(ArgumentError, 'The "fb" is nil') if fb.nil?
    @fb = fb
    @block = block
  end

  def insert
    f = @fb.insert
    @block.call(f, self)
    f
  end

  def query(term, maps = nil)
    Query.new(@fb.query(term, maps), self)
  end

  def import(bytes)
    probe = Factbase.new
    probe.import(bytes)
    probe.query('(always)').each { |f| @block.call(f, self) }
    @fb.import(probe.export)
  end

  def txn
    @fb.txn do |fbt|
      yield(Factbase::Pre.new(fbt, &@block))
    end
  end

  # Query decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  class Query
    include Enumerable
    decoor(:query)

    def initialize(query, fb)
      @query = query
      @fb = fb
    end

    def to_s
      @query.to_s
    end

    def each(fb = @fb, params = {}, &)
      @query.each(fb, params, &)
    end

    def one(fb = @fb, params = {})
      @query.one(fb, params)
    end

    def delete!(fb = @fb)
      @query.delete!(fb)
    end
  end
end
