# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require 'others'
require 'tago'
require 'time'
require_relative 'syntax'

# A decorator of a Factbase, that logs all operations.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Logged
  MONO = Process::CLOCK_MONOTONIC

  # Ctor.
  # @param [Factbase] fb The factbase to decorate
  # @param [Object] log The logging facility
  # @param [Integer] time_tolerate How many seconds are OK per request
  # @param [Print] tube The tube to use, if log is NIL
  def initialize(fb, log = nil, time_tolerate: 1, tube: nil)
    raise(ArgumentError, 'The "fb" is nil') if fb.nil?
    @origin = fb
    if log.nil?
      raise(ArgumentError, 'Either "log" or "tube" must be non-NIL') if tube.nil?
      @tube = tube
    else
      @tube = Tube.new(log, time_tolerate:)
    end
  end

  decoor(:origin)

  def insert
    @tube.say(Process.clock_gettime(MONO), "Inserted new fact ##{@origin.size} in #{Time.now.ago}")
    Fact.new(@origin.insert, tube: @tube)
  end

  def query(term, maps = nil)
    term = to_term(term) if term.is_a?(String)
    Query.new(term, maps, @tube, @origin)
  end

  def txn
    mono = Process.clock_gettime(MONO)
    id = nil
    rollback = false
    r =
      @origin.txn do |fbt|
        id = fbt.object_id
        yield(Factbase::Logged.new(fbt, tube: @tube))
      rescue Factbase::Rollback => e
        rollback = true
        raise(e)
      end
    if rollback
      @tube.say(mono, "Txn ##{id} rolled back in #{Time.now.ago}")
    else
      @tube.say(mono, "Txn ##{id} touched #{r} in #{Time.now.ago}")
    end
    r
  end

  # Printer of log messages.
  class Tube
    def initialize(log, time_tolerate: 1)
      @log = log
      @time_tolerate = time_tolerate
    end

    def say(start_mono, msg)
      m = :debug
      if Process.clock_gettime(Factbase::Logged::MONO) - start_mono > @time_tolerate
        msg = "#{msg} (slow!)"
        m = :warn
      end
      @log.__send__(m, msg)
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
      mono = Process.clock_gettime(Factbase::Logged::MONO) if args[0].to_s.end_with?('=')
      r = @fact.method_missing(*args)
      k = args[0].to_s
      v = args[1]
      if k.end_with?('=')
        s = v.is_a?(Time) ? v.utc.iso8601 : v.to_s
        s = v.to_s.inspect if v.is_a?(String)
        s = "#{s[0..(MAX_LENGTH / 2)]}...#{s[(-MAX_LENGTH / 2)..]}" if s.length > MAX_LENGTH
        @tube.say(mono, "Set '#{k[0..-2]}' to #{s} (#{v.class})")
      end
      r
    end
  end

  # Query decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  class Query
    def initialize(term, maps, tube, fb)
      @term = term
      @maps = maps
      @tube = tube
      @fb = fb
      @termtext = term.is_a?(Factbase::Term) ? term.to_s : term
    end

    def to_s
      @termtext
    end

    def each(fb = @fb, params = {}, &)
      return to_enum(__method__, fb, params) unless block_given?
      mono = Process.clock_gettime(Factbase::Logged::MONO)
      r = nil
      qry = @fb.query(@term, @maps)
      tail =
        Factbase::Logged.elapsed do
          r = qry.each(fb, params, &)
        end
      unless r.is_a?(Integer)
        raise(StandardError, ".query(#{@termtext.inspect}).each() of #{qry.class} returned #{r.class}")
      end
      if params.is_a?(Hash) && !params.empty?
        q = "#{@termtext} with {#{params.map do |k, v|
          "#{k}=#{v}"
        end.join(', ')}}"
      end
      q ||= @termtext
      if r.zero?
        @tube.say(mono, "Zero/#{@fb.size} facts found by #{q} #{tail}")
      else
        @tube.say(mono, "Found #{r}/#{@fb.size} fact(s) by #{q} #{tail}")
      end
      r
    end

    def one(fb = @fb, params = {})
      mono = Process.clock_gettime(Factbase::Logged::MONO)
      r = nil
      tail =
        Factbase::Logged.elapsed do
          r = @fb.query(@term, @maps).one(fb, params)
        end
      if r.nil?
        @tube.say(mono, "Nothing found by '#{@termtext}' #{tail}")
      else
        @tube.say(mono, "Found #{r} (#{r.class}) by '#{@termtext}' #{tail}")
      end
      r
    end

    def delete!(fb = @fb)
      r = nil
      mono = Process.clock_gettime(Factbase::Logged::MONO)
      before = @fb.size
      tail =
        Factbase::Logged.elapsed do
          r = @fb.query(@term, @maps).delete!(fb)
        end
      raise(StandardError, ".delete! of #{@term.class} returned #{r.class}") unless r.is_a?(Integer)
      if before.zero?
        @tube.say(mono, "There were no facts, nothing deleted by #{@term} #{tail}")
      elsif r.zero?
        @tube.say(mono, "No facts out of #{before} deleted by #{@term} #{tail}")
      else
        @tube.say(mono, "Deleted #{r} fact(s) out of #{before} by #{@term} #{tail}")
      end
      r
    end
  end

  def self.elapsed
    yield
    "in #{Time.now.ago}"
  end
end
