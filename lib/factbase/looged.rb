# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require 'others'
require 'time'
require 'loog'
require 'tago'
require_relative 'syntax'

# A decorator of a Factbase, that logs all operations.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Looged
  def initialize(fb, loog)
    raise 'The "fb" is nil' if fb.nil?
    @fb = fb
    raise 'The "loog" is nil' if loog.nil?
    @loog = loog
  end

  decoor(:fb)

  def insert
    start = Time.now
    f = @fb.insert
    @loog.debug("Inserted new fact ##{@fb.size} in #{start.ago}")
    Fact.new(f, @loog)
  end

  def query(query)
    Query.new(@fb, query, @loog)
  end

  def txn
    start = Time.now
    id = nil
    rollback = false
    r =
      @fb.txn do |fbt|
        id = fbt.object_id
        yield Factbase::Looged.new(fbt, @loog)
      rescue Factbase::Rollback => e
        rollback = true
        raise e
      end
    if rollback
      @loog.debug("Txn ##{id} rolled back in #{start.ago}")
    else
      @loog.debug("Txn ##{id} #{r.positive? ? 'modified' : 'didn\'t touch'} the factbase in #{start.ago}")
    end
    r
  end

  # Fact decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  #
  class Fact
    MAX_LENGTH = 64

    def initialize(fact, loog)
      @fact = fact
      @loog = loog
    end

    def to_s
      @fact.to_s
    end

    def all_properties
      @fact.all_properties
    end

    others do |*args|
      r = @fact.method_missing(*args)
      k = args[0].to_s
      v = args[1]
      s = v.is_a?(Time) ? v.utc.iso8601 : v.to_s
      s = v.to_s.inspect if v.is_a?(String)
      s = "#{s[0..MAX_LENGTH / 2]}...#{s[-MAX_LENGTH / 2..]}" if s.length > MAX_LENGTH
      @loog.debug("Set '#{k[0..-2]}' to #{s} (#{v.class})") if k.end_with?('=')
      r
    end
  end

  # Query decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  #
  class Query
    def initialize(fb, expr, loog)
      @fb = fb
      @expr = expr
      @loog = loog
    end

    def one(params = {})
      q = Factbase::Syntax.new(@fb, @expr).to_term.to_s
      r = nil
      tail =
        Factbase::Looged.elapsed do
          r = @fb.query(@expr).one(params)
        end
      if r.nil?
        @loog.debug("Nothing found by '#{q}' #{tail}")
      else
        @loog.debug("Found #{r} (#{r.class}) by '#{q}' #{tail}")
      end
      r
    end

    def each(params = {}, &)
      q = Factbase::Syntax.new(@fb, @expr).to_term.to_s
      if block_given?
        r = nil
        tail =
          Factbase::Looged.elapsed do
            r = @fb.query(@expr).each(params, &)
          end
        raise ".each of #{@query.class} returned #{r.class}" unless r.is_a?(Integer)
        if r.zero?
          @loog.debug("Nothing found by '#{q}' #{tail}")
        else
          @loog.debug("Found #{r} fact(s) by '#{q}' #{tail}")
        end
        r
      else
        array = []
        tail =
          Factbase::Looged.elapsed do
            @fb.query(@expr).each(params) do |f|
              array << f
            end
          end
        if array.empty?
          @loog.debug("Nothing found by '#{q}' #{tail}")
        else
          @loog.debug("Found #{array.size} fact(s) by '#{q}' #{tail}")
        end
        array
      end
    end

    def delete!
      r = nil
      before = @fb.size
      tail =
        Factbase::Looged.elapsed do
          r = @fb.query(@expr).delete!
        end
      raise ".delete! of #{@query.class} returned #{r.class}" unless r.is_a?(Integer)
      if before.zero?
        @loog.debug("There were no facts, nothing deleted by '#{@expr}' #{tail}")
      elsif r.zero?
        @loog.debug("No facts out of #{before} deleted by '#{@expr}' #{tail}")
      else
        @loog.debug("Deleted #{r} fact(s) out of #{before} by '#{@expr}' #{tail}")
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
