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

require_relative 'fact'

# Term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Term
  def initialize(operator, operands)
    @op = operator
    @operands = operands
  end

  # Does it match the map?
  # @param [Map] The map
  # @return [bool] TRUE if matches
  def matches?(map)
    send(@op, map)
  end

  def to_s
    items = []
    items << @op
    items += @operands.map do |o|
      if o.is_a?(String)
        "'#{o}'"
      else
        o.to_s
      end
    end
    "(#{items.join(' ')})"
  end

  private

  def or(map)
    @operands.each do |o|
      return true if o.matches?(map)
    end
    false
  end

  def and(map)
    @operands.each do |o|
      return false unless o.matches?(map)
    end
    true
  end

  def exists(map)
    k = @operands[0].to_s
    !map[k].nil?
  end

  def absent(map)
    k = @operands[0].to_s
    map[k].nil?
  end

  def eq(map)
    k = @operands[0].to_s
    v = map[k]
    return false if v.nil?
    v[0] == @operands[1]
  end

  def lt(map)
    k = @operands[0].to_s
    v = map[k]
    return false if v.nil?
    v[0] < @operands[1]
  end

  def gt(map)
    k = @operands[0].to_s
    v = map[k]
    return false if v.nil?
    v[0] > @operands[1]
  end
end
