# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require 'tago'
require 'timeout'
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

    def each(fb = @fb, params = {})
      return to_enum(__method__, fb, params) unless block_given?
      n = 0
      budget = Budget.new(@timeout)
      impatient('each', budget) do
        @fb.query(@term, @maps).each(fb, params) do |fact|
          budget.pause { yield(fact) }
          n += 1
        end
      end
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

    def impatient(name, budget = Budget.new(@timeout), &)
      budget.watch(&)
    rescue Timeout::Error => e
      raise(
        StandardError,
        "#{name}() timed out after #{@timeout.seconds} (#{e.message}), fb size is #{@fb.size}: #{@term}"
      )
    end
  end

  # Time budget of a query, which is spent only while the query works.
  #
  # The query runs in the thread and the fiber of the caller, so it has the
  # same stack and holds the same locks. A watchdog thread raises
  # +Timeout::Error+ in it when the budget is over. The clock stops while
  # the block of the caller runs, so a slow consumer never times out.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  class Budget
    def initialize(seconds)
      @left = seconds
      @since = nil
      @done = false
      @lock = Mutex.new
      @wake = ConditionVariable.new
    end

    # Run the block, interrupting it when the budget is over.
    def watch
      @lock.synchronize { @since = now }
      owner = Thread.current
      dog = Thread.new { guard(owner) }
      begin
        yield
      ensure
        @lock.synchronize do
          @done = true
          @wake.signal
        end
        dog.join
      end
    end

    # Run the block with the clock stopped.
    def pause
      Thread.handle_interrupt(Timeout::Error => :never) do
        @lock.synchronize do
          @left -= now - @since
          @since = nil
        end
        Thread.handle_interrupt(Timeout::Error => :immediate) { Thread.pass } if Thread.pending_interrupt?
      end
      begin
        yield
      ensure
        @lock.synchronize do
          @since = now
          @wake.signal
        end
      end
    end

    private

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def guard(owner)
      @lock.synchronize do
        until @done
          if @since.nil?
            @wake.wait(@lock)
            next
          end
          rest = @left - (now - @since)
          if rest <= 0
            owner.raise(Timeout::Error, 'execution expired')
            break
          end
          @wake.wait(@lock, rest)
        end
      end
    end
  end
end
