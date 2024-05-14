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

  def initialize(operator, operands)
    @op = operator
    @operands = operands
  end

  # Does it match the fact?
  # @param [Factbase::Fact] The fact
  # @return [bool] TRUE if matches
  def matches?(fact)
    send(@op, fact)
  end

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
    !@operands[0].matches?(fact)
  end

  def or(fact)
    @operands.each do |o|
      return true if o.matches?(fact)
    end
    false
  end

  def and(fact)
    @operands.each do |o|
      return false unless o.matches?(fact)
    end
    true
  end

  def exists(fact)
    assert_args(1)
    k = @operands[0].to_s
    !fact[k].nil?
  end

  def absent(fact)
    assert_args(1)
    k = @operands[0].to_s
    fact[k].empty?
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

  def arithmetic(op, fact)
    assert_args(2)
    k = @operands[0].to_s
    v = fact[k]
    return false if v.nil?
    v = [v] unless v.is_a?(Array)
    v.any? { |vv| vv.send(op, @operands[1]) }
  end

  def assert_args(num)
    c = @operands.size
    raise "Too many (#{c}) operands for '#{@op}' (#{num} expected)" if c > num
    raise "Too few (#{c}) operands for '#{@op}' (#{num} expected)" if c < num
  end
end
