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
require_relative '../factbase/syntax'

# A decorator of a Factbase, that checks rules on every set.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Rules
  def initialize(fb, rules, check = Check.new(rules))
    @fb = fb
    @rules = rules
    @check = check
  end

  def dup
    Factbase::Rules.new(@fb.dup, @rules, @check)
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

  def txn(this = self, &)
    before = @check
    @check = Blind.new
    modified = @fb.txn(this, &)
    @check = before
    if modified
      @fb.query('(always)').each do |f|
        @check.it(f)
      end
    end
    modified
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
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  class Check
    def initialize(expr)
      @expr = expr
    end

    def it(fact)
      return if Factbase::Syntax.new(@expr).to_term.evaluate(fact, [])
      e = "#{@expr[0..32]}..." if @expr.length > 32
      raise "The fact doesn't match the #{e.inspect} rule: #{fact}"
    end
  end

  # Check one fact (never complaining).
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  class Blind
    def it(_fact)
      true
    end
  end
end
