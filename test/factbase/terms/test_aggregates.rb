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

require 'minitest/autorun'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/syntax'

# Aggregates test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestAggregates < Minitest::Test
  def test_aggregation
    maps = [
      { 'x' => [1], 'y' => [0], 'z' => [4] },
      { 'x' => [2], 'y' => [42], 'z' => [3] },
      { 'x' => [3], 'y' => [42], 'z' => [5] },
      { 'x' => [4], 'y' => [42], 'z' => [2] },
      { 'x' => [5], 'y' => [42], 'z' => [1] },
      { 'x' => [8], 'y' => [0], 'z' => [6] }
    ]
    {
      '(eq x (agg (eq y 42) (min x)))' => '(eq x 2)',
      '(eq z (agg (eq y 0) (max z)))' => '(eq x 8)',
      '(eq x (agg (and (eq y 42) (gt z 1)) (max x)))' => '(eq x 4)',
      '(and (eq x (agg (eq y 42) (min x))) (eq z 3))' => '(eq x 2)',
      '(eq x (agg (eq y 0) (nth 0 x)))' => '(eq x 1)',
      '(eq x (agg (eq y 0) (first x)))' => '(eq x 1)',
      '(agg (eq foo 42) (always))' => '(eq x 1)'
    }.each do |q, r|
      t = Factbase::Syntax.new(q).to_term
      f = maps.find { |m| t.evaluate(fact(m), maps) }
      assert(!f.nil?, "nothing found by: #{q}")
      assert(Factbase::Syntax.new(r).to_term.evaluate(fact(f), []))
    end
  end

  def test_empty
    maps = [
      { 'x' => [1], 'y' => [0], 'z' => [4] },
      { 'x' => [8], 'y' => [0] }
    ]
    {
      '(empty (eq y 42))' => true,
      '(empty (eq x 1))' => false
    }.each do |q, r|
      t = Factbase::Syntax.new(q).to_term
      assert_equal(r, t.evaluate(nil, maps), q)
    end
  end

  private

  def fact(map = {})
    Factbase::Fact.new(Mutex.new, map)
  end
end
