# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require 'timeout'
require_relative 'syntax'

# A decorator of a Factbase, that terminates long-running queries.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Impatient
  # Ctor.
  # @param [Factbase] fb The factbase to decorate
  # @param [Integer] timeout Timeout in seconds
  def initialize(fb, timeout: 15)
    raise 'The "fb" is nil' if fb.nil?
    @origin = fb
    @timeout = timeout
  end

  decoor(:origin)

  def insert
    @origin.insert
  end

  def query(term, maps = nil)
    term = to_term(term) if term.is_a?(String)
    Query.new(term, maps, @timeout, @origin)
  end

  def txn
    @origin.txn do |fbt|
      yield Factbase::Impatient.new(fbt, timeout: @timeout)
    end
  end

  # Query decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  class Query
    def initialize(term, maps, timeout, fb)
      @term = term
      @maps = maps
      @timeout = timeout
      @fb = fb
    end

    def to_s
      @term.to_s
    end

    def each(fb = @fb, params = {}, &)
      return to_enum(__method__, fb, params) unless block_given?
      qry = @fb.query(@term, @maps)
      Timeout.timeout(@timeout) do
        qry.each(fb, params, &)
      end
    rescue Timeout::Error => e
      raise "Query timed out after #{@timeout} seconds: #{e.message}"
    end

    def one(fb = @fb, params = {})
      qry = @fb.query(@term, @maps)
      Timeout.timeout(@timeout) do
        qry.one(fb, params)
      end
    rescue Timeout::Error => e
      raise "Query timed out after #{@timeout} seconds: #{e.message}"
    end

    def delete!(fb = @fb)
      qry = @fb.query(@term, @maps)
      Timeout.timeout(@timeout) do
        qry.delete!(fb)
      end
    rescue Timeout::Error => e
      raise "Query timed out after #{@timeout} seconds: #{e.message}"
    end
  end
end
