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

require 'loog'

# A decorator of a Factbase, that logs all operations.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Looged
  def initialize(fb, loog)
    @fb = fb
    @loog = loog
  end

  def empty?
    @fb.empty?
  end

  def size
    @fb.size
  end

  def insert
    f = @fb.insert
    @loog.debug("Inserted fact ##{f.id}")
    Fact.new(f, @loog)
  end

  def query(query)
    Query.new(@fb.query(query), query, @loog)
  end

  def export
    @fb.export
  end

  def import(bytes)
    @fb.import(bytes)
  end

  def to_json(opt = nil)
    @fb.to_json(opt)
  end

  def to_xml
    @fb.to_xml
  end

  def to_yaml
    @fb.to_yaml
  end

  # Fact decorator.
  class Fact
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
      @loog.debug("Set '#{k[0..-2]}' to #{v.to_s.inspect} (#{v.class})") if k.end_with?('=')
      r
    end

    # rubocop:disable Style/OptionalBooleanParameter
    def respond_to?(method, include_private = false)
      # rubocop:enable Style/OptionalBooleanParameter
      @fact.respond_to?(method, include_private)
    end

    def respond_to_missing?(method, include_private = false)
      @fact.respond_to_missing?(method, include_private)
    end
  end

  # Query decorator.
  class Query
    def initialize(query, expr, loog)
      @query = query
      @expr = expr
      @loog = loog
    end

    def each(&)
      if block_given?
        r = @query.each(&)
        raise ".each of #{@query.class} returned #{r.class}" unless r.is_a?(Integer)
        if r.zero?
          @loog.debug("Nothing found by '#{@expr}'")
        else
          @loog.debug("Found #{r} fact(s) by '#{@expr}'")
        end
        r
      else
        array = []
        # rubocop:disable Style/MapIntoArray
        @query.each do |f|
          array << f
        end
        # rubocop:enable Style/MapIntoArray
        if array.empty?
          @loog.debug("Nothing found by '#{@expr}'")
        else
          @loog.debug("Found #{array.size} fact(s) by '#{@expr}'")
        end
        array
      end
    end

    def delete!
      r = @query.delete!
      raise ".delete! of #{@query.class} returned #{r.class}" unless r.is_a?(Integer)
      if r.zero?
        @loog.debug("Nothing deleted by '#{@expr}'")
      else
        @loog.debug("Deleted #{r} fact(s) by '#{@expr}'")
      end
      r
    end
  end
end
