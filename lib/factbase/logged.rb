# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require 'others'
require 'time'
require 'tago'
require_relative 'syntax'

# A decorator of a Factbase, that logs all operations.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Logged
  # Ctor.
  # @param [Factbase] fb The factbase to decorate
  # @param [Object] log The logging facility
  # @param [Integer] time_tolerate How many seconds are OK per request
  # @param [Print] tube The tube to use, if log is NIL
  def initialize(fb, log = nil, time_tolerate: 1, tube: nil)
    raise 'The "fb" is nil' if fb.nil?
    @fb = fb
    if log.nil?
      raise 'Either "log" or "tube" must be non-NIL' if tube.nil?
      @tube = tube
    else
      @tube = Tube.new(log, time_tolerate:)
    end
  end

  decoor(:fb)

  def insert
    start = Time.now
    f = @fb.insert
    @tube.say(start, "Inserted new fact ##{@fb.size} in #{start.ago}")
    Fact.new(f, tube: @tube)
  end

  def query(query)
    Query.new(query, @tube, @fb)
  end

  def txn
    start = Time.now
    id = nil
    rollback = false
    r =
      @fb.txn do |fbt|
        id = fbt.object_id
        yield Factbase::Logged.new(fbt, tube: @tube)
      rescue Factbase::Rollback => e
        rollback = true
        raise e
      end
    if rollback
      @tube.say(start, "Txn ##{id} rolled back in #{start.ago}")
    else
      @tube.say(start, "Txn ##{id} touched #{r} in #{start.ago}")
    end
    r
  end

  # Printer of log messages.
  class Tube
    def initialize(log, time_tolerate: 1)
      @log = log
      @time_tolerate = time_tolerate
    end

    def say(start, msg)
      m = :debug
      if Time.now - start > @time_tolerate
        msg = "#{msg} (slow!)"
        m = :warn
      end
      @log.send(m, msg)
    end
  end

  # Fact decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  #
  class Fact
    MAX_LENGTH = 64

    def initialize(fact, tube: nil, log: nil)
      @fact = fact
      @tube =
        if log.nil?
          tube
        else
          Tube.new(log)
        end
    end

    def to_s
      @fact.to_s
    end

    def all_properties
      @fact.all_properties
    end

    others do |*args|
      start = Time.now
      r = @fact.method_missing(*args)
      k = args[0].to_s
      v = args[1]
      s = v.is_a?(Time) ? v.utc.iso8601 : v.to_s
      s = v.to_s.inspect if v.is_a?(String)
      s = "#{s[0..MAX_LENGTH / 2]}...#{s[-MAX_LENGTH / 2..]}" if s.length > MAX_LENGTH
      @tube.say(start, "Set '#{k[0..-2]}' to #{s} (#{v.class})") if k.end_with?('=')
      r
    end
  end

  # Query decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  #
  class Query
    def initialize(expr, tube, fb)
      @expr = expr
      @tube = tube
      @fb = fb
    end

    def one(fb = @fb, params = {})
      start = Time.now
      q = Factbase::Syntax.new(@expr).to_term.to_s
      r = nil
      tail =
        Factbase::Logged.elapsed do
          r = fb.query(@expr).one(fb, params)
        end
      if r.nil?
        @tube.say(start, "Nothing found by '#{q}' #{tail}")
      else
        @tube.say(start, "Found #{r} (#{r.class}) by '#{q}' #{tail}")
      end
      r
    end

    def each(fb = @fb, params = {}, &)
      start = Time.now
      q = Factbase::Syntax.new(@expr).to_term.to_s
      if block_given?
        r = nil
        tail =
          Factbase::Logged.elapsed do
            r = fb.query(@expr).each(fb, params, &)
          end
        raise ".each of #{@expr.class} returned #{r.class}" unless r.is_a?(Integer)
        if r.zero?
          @tube.say(start, "Nothing found by '#{q}' #{tail}")
        else
          @tube.say(start, "Found #{r} fact(s) by '#{q}' #{tail}")
        end
        r
      else
        array = []
        tail =
          Factbase::Logged.elapsed do
            fb.query(@expr).each(fb, params) do |f|
              array << f
            end
          end
        if array.empty?
          @tube.say(start, "Nothing found by '#{q}' #{tail}")
        else
          @tube.say(start, "Found #{array.size} fact(s) by '#{q}' #{tail}")
        end
        array
      end
    end

    def delete!(fb = @fb)
      r = nil
      start = Time.now
      before = fb.size
      tail =
        Factbase::Logged.elapsed do
          r = @fb.query(@expr).delete!(fb)
        end
      raise ".delete! of #{@expr.class} returned #{r.class}" unless r.is_a?(Integer)
      if before.zero?
        @tube.say(start, "There were no facts, nothing deleted by '#{@expr}' #{tail}")
      elsif r.zero?
        @tube.say(start, "No facts out of #{before} deleted by '#{@expr}' #{tail}")
      else
        @tube.say(start, "Deleted #{r} fact(s) out of #{before} by '#{@expr}' #{tail}")
      end
      r
    end
  end

  def self.elapsed
    start = Time.now
    yield
    "in #{start.ago}"
  end
end
