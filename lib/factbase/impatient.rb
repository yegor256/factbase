# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require 'tago'
require 'timeout'
require_relative 'enumerated'
require_relative 'syntax'

# A decorator of a Factbase, that terminates long-running queries.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Impatient
  # Ctor.
  # @param [Factbase] fb The factbase to decorate
  # @param [Integer] timeout Timeout in seconds
  def initialize(fb, timeout: 15)
    raise(ArgumentError, 'The "fb" is nil') if fb.nil?
    @origin = fb
    @timeout = Float(timeout)
    raise(ArgumentError, "The \"timeout\" must be positive, while #{timeout} given") unless @timeout.positive?
    raise(ArgumentError, "The \"timeout\" must be finite, while #{timeout} given") unless @timeout.finite?
  end

  decoor(:origin)
  include Factbase::Enumerated

  def insert
    @origin.insert
  end

  def query(term, maps = nil)
    term = to_term(term) if term.is_a?(String)
    Query.new(term, maps, @timeout, @origin)
  end

  def txn
    @origin.txn do |fbt|
      yield(Factbase::Impatient.new(fbt, timeout: @timeout))
    end
  end

  # Query decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  class Query
    include Enumerable

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
      enum = @fb.query(@term, @maps).each(fb, params)
      n = 0
      left = @timeout
      stopped = nil
      fallback = nil
      loop do
        # rubocop:disable Elegant/NoRedundantVariable
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        begin
          fact = impatient('each', left) { enum.next }
        rescue ThreadError => e
          raise(e) unless n.zero? && deadlock?(e)
          fallback = materialize(fb, params)
          break
        end
        # rubocop:enable Elegant/NoRedundantVariable
        left -= Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        begin
          yield(fact)
        rescue StopIteration => e
          stopped = e
          break
        end
        n += 1
      end
      unless fallback.nil?
        fallback.each(&)
        return fallback.size
      end
      raise(stopped) if stopped
      n
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

    # Detects the monitor/fiber deadlock that may occur when the origin query,
    # running inside its own fiber, tries to re-enter a monitor already owned
    # by the enclosing fiber of the same thread, e.g. when Impatient decorates
    # a synchronized factbase and the query is pulled inside txn.
    #
    # @param [ThreadError] err The error to inspect
    # @return [Boolean] True when the error is that specific deadlock
    def deadlock?(err)
      err.message.include?('fiber belonging to the same thread')
    end

    # Materializes the entire query result in the current fiber, as a single
    # read, so that a monitor owned by the caller's fiber is re-entered by
    # that same fiber, avoiding the fiber-to-fiber deadlock of the enumerator.
    #
    # @param [Factbase] fb The factbase to run the query against
    # @param [Hash] params Query params
    # @return [Array] All facts matching the query
    def materialize(fb, params)
      impatient('each', @timeout) { @fb.query(@term, @maps).each(fb, params).to_a }
    end

    def impatient(name, budget = @timeout, &)
      raise(StandardError, "#{name}() ran out of time, fb size is #{@fb.size}: #{@term}") if budget <= 0
      Timeout.timeout(budget, &)
    rescue Timeout::Error => e
      raise(
        StandardError,
        "#{name}() timed out after #{@timeout.seconds} (#{e.message}), fb size is #{@fb.size}: #{@term}"
      )
    end
  end
end
