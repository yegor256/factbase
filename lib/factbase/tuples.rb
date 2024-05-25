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

# Tuples.
#
# With the help of this class, it's possible to select a few facts
# from a factbase at a time, which depend on each other. For example,
# it's necessary to find a fact where the +name+ is set and then find
# another fact, where the salary is the +salary+ is the same as in the
# first found fact. Here is how:
#
#  Factbase::Tuples.new(qt, ['(exists name)', '(eq salary, {f0.salary})']).each do |a, b|
#    puts a.name
#    puts b.salary
#  end
#
# Here, the +{f0.salary}+ is a special substitution place, which is replaced
# by the +salary+ of the fact that is found by the previous query. The indexing
# of queries starts from zero.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Tuples
  def initialize(fb, queries)
    @fb = fb
    @queries = queries
  end

  # Iterate them one by one.
  # @yield [Array<Fact>] Arrays of facts one-by-one
  # @return [Integer] Total number of arrays yielded
  def each(&)
    return to_enum(__method__) unless block_given?
    each_rec([], @queries, &)
  end

  private

  def each_rec(facts, tail, &)
    qq = tail.dup
    q = qq.shift
    return if q.nil?
    qt = q.gsub(/\{f([0-9]+).([a-z0-9_]+)\}/) do
      facts[Regexp.last_match[1].to_i].send(Regexp.last_match[2])
    end
    @fb.query(qt).each do |f|
      fs = facts + [f]
      if qq.empty?
        yield fs
      else
        each_rec(fs, qq, &)
      end
    end
  end
end
