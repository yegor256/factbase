# frozen_string_literal: true

# Copyright (c) 2024 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'time'
require 'loog'
require 'tago'
require_relative 'syntax'

# A decorator of a Factbase, that logs all operations.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Looged
  def initialize(fb, loog)
    @fb = fb
    @loog = loog
  end

  def dup
    Factbase::Looged.new(@fb.dup, @loog)
  end

  def size
    @fb.size
  end

  def insert
    f = @fb.insert
    @loog.debug("Inserted new fact ##{@fb.size}")
    Fact.new(f, @loog)
  end

  def query(query)
    Query.new(@fb, query, @loog)
  end

  def txn(this = self, &)
    start = Time.now
    id = nil
    rollback = false
    r = @fb.txn(this) do |fbt|
      id = fbt.object_id
      yield fbt
    rescue Factbase::Rollback => e
      rollback = true
      raise e
    end
    if rollback
      @loog.debug("Txn ##{id} rolled back in #{start.ago}")
    else
      @loog.debug("Txn ##{id} #{r ? 'modified' : 'didn\'t touch'} the factbase in #{start.ago}")
    end
    r
  end

  def export
    @fb.export
  end

  def import(bytes)
    @fb.import(bytes)
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

    def method_missing(*args)
      r = @fact.method_missing(*args)
      k = args[0].to_s
      v = args[1]
      s = v.is_a?(Time) ? v.utc.iso8601 : v.to_s
      s = v.to_s.inspect if v.is_a?(String)
      s = "#{s[0..MAX_LENGTH / 2]}...#{s[-MAX_LENGTH / 2..]}" if s.length > MAX_LENGTH
      @loog.debug("Set '#{k[0..-2]}' to #{s} (#{v.class})") if k.end_with?('=')
      r
    end

    # rubocop:disable Style/OptionalBooleanParameter
    def respond_to?(_method, _include_private = false)
      # rubocop:enable Style/OptionalBooleanParameter
      true
    end

    def respond_to_missing?(_method, _include_private = false)
      true
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
      q = Factbase::Syntax.new(@expr).to_term.to_s
      r = nil
      tail = Factbase::Looged.elapsed do
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
      q = Factbase::Syntax.new(@expr).to_term.to_s
      if block_given?
        r = nil
        tail = Factbase::Looged.elapsed do
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
        tail = Factbase::Looged.elapsed do
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
      tail = Factbase::Looged.elapsed do
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
