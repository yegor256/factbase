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

require 'decoor'
require_relative '../factbase'

# A decorator of a Factbase, that checks invariants on every set.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Inv
  decoor(:fb)

  def initialize(fb, &block)
    @fb = fb
    @block = block
  end

  def dup
    Factbase::Inv.new(@fb.dup, &@block)
  end

  def insert
    Fact.new(@fb.insert, @block)
  end

  def query(query)
    Query.new(@fb.query(query), @block)
  end

  def txn(this = self, &)
    @fb.txn(this, &)
  end

  # Fact decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  #
  class Fact
    decoor(:fact)

    def initialize(fact, block)
      @fact = fact
      @block = block
    end

    def to_s
      @fact.to_s
    end

    def method_missing(*args)
      k = args[0].to_s
      @block.call(k[0..-2], args[1]) if k.end_with?('=')
      @fact.method_missing(*args)
    end
  end

  # Query decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  #
  class Query
    decoor(:query)

    def initialize(query, block)
      @query = query
      @block = block
    end

    def each
      return to_enum(__method__) unless block_given?
      @query.each do |f|
        yield Fact.new(f, @block)
      end
    end
  end
end
