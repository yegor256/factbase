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

# Spy.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Spy
  def initialize(fb, key)
    @fb = fb
    @key = key
    @caught = []
  end

  def caught_keys
    @caught
  end

  def dup
    Factbase::Spy.new(@fb.dup, @key)
  end

  def query(expr)
    scan(Factbase::Syntax.new(expr).to_term)
    @fb.query(expr)
  end

  def insert
    SpyFact.new(@fb.insert, @key, @caught)
  end

  def export
    @fb.export
  end

  def txn(this = self, &)
    @fb.txn(this, &)
  end

  def import(data)
    @fb.import(data)
  end

  # A fact that is spying.
  class SpyFact
    def initialize(fact, key, caught)
      @fact = fact
      @key = key
      @caught = caught
    end

    def method_missing(*args)
      @caught << args[1] if args[0].to_s == "#{@key}="
      @fact.method_missing(*args)
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

  private

  def scan(term)
    @caught << term.operands[1] if term.op == :eq && term.operands[0].to_s == @key
    term.operands.each do |o|
      scan(o) if o.is_a?(Factbase::Term)
    end
  end
end
