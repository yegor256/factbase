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

require_relative '../factbase'

# A decorator of a Factbase, that checks rules on every set.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Rules
  def initialize(fb, rules)
    @fb = fb
    @check = Check.new(fb, rules)
  end

  def size
    @fb.size
  end

  def insert
    Fact.new(@fb.insert, @check)
  end

  def query(query)
    Query.new(@fb.query(query), @check)
  end

  def export
    @fb.export
  end

  def import(bytes)
    @fb.import(bytes)
  end

  # Fact decorator.
  class Fact
    def initialize(fact, check)
      @fact = fact
      @check = check
    end

    def to_s
      @fact.to_s
    end

    def method_missing(*args)
      r = @fact.method_missing(*args)
      k = args[0].to_s
      @check.it(self) if k.end_with?('=')
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
    def initialize(query, check)
      @query = query
      @check = check
    end

    def each
      return to_enum(__method__) unless block_given?
      @query.each do |f|
        yield Fact.new(f, @check)
      end
    end

    def delete!
      @query.delete!
    end
  end

  # Check one fact.
  class Check
    def initialize(fb, expr)
      @fb = fb
      @expr = expr
    end

    def it(fact)
      return if Factbase::Syntax.new(@expr).to_term.eval(fact)
      raise "The fact is in invalid state: #{fact}"
    end
  end
end
