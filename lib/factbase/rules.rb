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
require 'others'
require_relative '../factbase'
require_relative '../factbase/syntax'

# A decorator of a Factbase, that checks rules on every set.
#
# Say, you want every fact to have +foo+ property. You want any attempt
# to insert a fact without this property to lead to a runtime error. Here is how:
#
#  fb = Factbase.new
#  fb = Factabase::Rules.new(fb, '(exists foo)')
#  fb.txn do |fbt|
#    f = fbt.insert
#    f.bar = 3 # No exception here
#  end # Runtime exception here (transaction won't commit)
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Rules
  decoor(:fb)

  def initialize(fb, rules, check = Check.new(rules), uid: nil)
    raise 'The "fb" is nil' if fb.nil?
    @fb = fb
    raise 'The "rules" is nil' if rules.nil?
    @rules = rules
    raise 'The "check" is nil' if check.nil?
    @check = check
    @uid = uid
  end

  def dup
    Factbase::Rules.new(@fb.dup, @rules, @check, uid: @uid)
  end

  def insert
    Fact.new(@fb.insert, @check)
  end

  def query(query)
    Query.new(@fb.query(query), @check)
  end

  def txn(this = self, &)
    before = @check
    later = Later.new(@uid)
    @check = later
    @fb.txn(this) do |fbt|
      yield fbt
      @check = before
      fbt.query('(always)').each do |f|
        next unless later.include?(f)
        @check.it(f)
      end
    end
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

    others do |*args|
      r = @fact.method_missing(*args)
      k = args[0].to_s
      @check.it(@fact) if k.end_with?('=')
      r
    end
  end

  # Query decorator.
  #
  # This is an internal class, it is not supposed to be instantiated directly.
  #
  class Query
    decoor(:query)

    def initialize(query, check)
      @query = query
      @check = check
    end

    def each(params = {})
      return to_enum(__method__, params) unless block_given?
      @query.each do |f|
        yield Fact.new(f, @check)
      end
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
  class Later
    def initialize(uid)
      @uid = uid
      @facts = Set.new
    end

    def it(fact)
      @facts << fact.send(@uid) unless @uid.nil?
    end

    def include?(fact)
      return true if @uid.nil?
      @facts.include?(fact.send(@uid))
    end
  end
end
