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
require_relative 'fact'

# Term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Term
  attr_reader :op, :operands

  # Ctor.
  # @param [Symbol] operator Operator
  # @param [Array] operands Operands
  def initialize(operator, operands)
    @op = operator
    @operands = operands
  end

  # Does it match the fact?
  # @param [Factbase::Fact] fact The fact
  # @return [bool] TRUE if matches
  def eval(fact)
    send(@op, fact)
  end

  # Turns it into a string.
  # @return [String] The string of it
  def to_s
    items = []
    items << @op
    items += @operands.map do |o|
      if o.is_a?(String)
        "'#{o.gsub("'", "\\\\'").gsub('"', '\\\\"')}'"
      elsif o.is_a?(Time)
        o.utc.iso8601
      else
        o.to_s
      end
    end
    "(#{items.join(' ')})"
  end

  private

  def nil(_fact)
    assert_args(0)
    true
  end

  def not(fact)
    assert_args(1)
    !@operands[0].eval(fact)
  end

  def or(fact)
    @operands.each do |o|
      return true if o.eval(fact)
    end
    false
  end

  def and(fact)
    @operands.each do |o|
      return false unless o.eval(fact)
    end
    true
  end

  def when(fact)
    assert_args(2)
    a = @operands[0]
    b = @operands[1]
    !a.eval(fact) || (a.eval(fact) && b.eval(fact))
  end

  def exists(fact)
    assert_args(1)
    !by_symbol(0, fact).nil?
  end

  def absent(fact)
    assert_args(1)
    by_symbol(0, fact).nil?
  end

  def eq(fact)
    arithmetic(:==, fact)
  end

  def lt(fact)
    arithmetic(:<, fact)
  end

  def gt(fact)
    arithmetic(:>, fact)
  end

  def size(fact)
    assert_args(1)
    v = by_symbol(0, fact)
    return 0 if v.nil?
    return 1 unless v.is_a?(Array)
    v.size
  end

  def type(fact)
    assert_args(1)
    v = by_symbol(0, fact)
    return 'nil' if v.nil?
    v.class.to_s
  end

  def arithmetic(op, fact)
    assert_args(2)
    lefts = the_value(0, fact)
    return false if lefts.nil?
    rights = the_value(1, fact)
    return false if rights.nil?
    lefts.any? do |l|
      l = l.floor if l.is_a?(Time) && op == :==
      rights.any? do |r|
        r = r.floor if r.is_a?(Time) && op == :==
        l.send(op, r)
      end
    end
  end

  def assert_args(num)
    c = @operands.size
    raise "Too many (#{c}) operands for '#{@op}' (#{num} expected)" if c > num
    raise "Too few (#{c}) operands for '#{@op}' (#{num} expected)" if c < num
  end

  def by_symbol(pos, fact)
    o = @operands[pos]
    raise "A symbol expected at ##{pos}, but provided: #{o}" unless o.is_a?(Symbol)
    k = o.to_s
    fact[k]
  end

  def the_value(pos, fact)
    v = @operands[pos]
    v = v.eval(fact) if v.is_a?(Factbase::Term)
    v = fact[v.to_s] if v.is_a?(Symbol)
    return v if v.nil?
    v = [v] unless v.is_a?(Array)
    v
  end
end
