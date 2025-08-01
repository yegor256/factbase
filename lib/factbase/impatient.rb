# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require 'tago'
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
    @timeout = timeout.to_f
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
      a =
        impatient('each') do
          @fb.query(@term, @maps).each(fb, params).to_a
        end
      return a unless block_given?
      yielded = 0
      a.each do |f|
        yield f
        yielded += 1
      end
      yielded
    end

    def one(fb = @fb, params = {})
      impatient('one') do
        @fb.query(@term, @maps).one(fb, params)
      end
    end

    def delete!(fb = @fb)
      impatient('delete!') do
        @fb.query(@term, @maps).delete!(fb)
      end
    end

    private

    def impatient(name, &)
      Timeout.timeout(@timeout, &)
    rescue Timeout::Error => e
      raise "#{name}() timed out after #{@timeout.seconds} (#{e.message}), fb size is #{@fb.size}: #{@term}"
    end
  end
end
