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

require_relative '../../factbase'

# Aggregating terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
module Factbase::Term::Aggregates
  def min(_fact, maps)
    assert_args(1)
    best(maps) { |v, b| v < b }
  end

  def max(_fact, maps)
    assert_args(1)
    best(maps) { |v, b| v > b }
  end

  def count(_fact, maps)
    maps.size
  end

  def nth(_fact, maps)
    assert_args(2)
    pos = @operands[0]
    raise "An integer expected, but #{pos} provided" unless pos.is_a?(Integer)
    k = @operands[1]
    raise "A symbol expected, but #{k} provided" unless k.is_a?(Symbol)
    maps[pos][k.to_s]
  end

  def first(_fact, maps)
    assert_args(1)
    k = @operands[0]
    raise "A symbol expected, but #{k} provided" unless k.is_a?(Symbol)
    first = maps[0]
    return nil if first.nil?
    first[k.to_s]
  end

  def sum(_fact, maps)
    k = @operands[0]
    raise "A symbol expected, but '#{k}' provided" unless k.is_a?(Symbol)
    sum = 0
    maps.each do |m|
      vv = m[k.to_s]
      next if vv.nil?
      vv = [vv] unless vv.is_a?(Array)
      vv.each do |v|
        sum += v
      end
    end
    sum
  end

  def agg(fact, maps)
    assert_args(2)
    selector = @operands[0]
    raise "A term expected, but '#{selector}' provided" unless selector.is_a?(Factbase::Term)
    term = @operands[1]
    raise "A term expected, but '#{term}' provided" unless term.is_a?(Factbase::Term)
    subset = maps.select { |m| selector.evaluate(Factbase::Tee.new(Factbase::Fact.new(Mutex.new, m), fact), maps) }
    term.evaluate(nil, subset)
  end
end
