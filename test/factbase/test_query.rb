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
require 'time'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/query'

# Query test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestQuery < Minitest::Test
  def test_simple_parsing
    maps = []
    maps << { 'foo' => [42] }
    q = Factbase::Query.new(maps, Mutex.new, '(eq foo 42)')
    assert_equal(
      1,
      q.each do |f|
        assert_equal(42, f.foo)
      end
    )
  end

  def test_complex_parsing
    maps = []
    maps << { 'num' => 42, 'name' => 'Jeff' }
    maps << { 'pi' => 3.14, 'num' => [42, 66, 0], 'name' => 'peter' }
    maps << { 'time' => Time.now - 100, 'num' => 0 }
    {
      '(eq num 444)' => 0,
      '(eq time 0)' => 0,
      '(gt num 60)' => 1,
      "(and (lt pi 100) \n\n (gt num 1000))" => 0,
      '(exists pi)' => 1,
      '(eq pi +3.14)' => 1,
      '(not (exists hello))' => 3,
      '(eq "Integer" (type num))' => 2,
      '(when (eq num 0) (exists time))' => 2,
      '(many num)' => 1,
      '(one num)' => 2,
      '(gt num (minus 1 (either (at 0 (prev num)) 0)))' => 3,
      '(and (not (many num)) (eq num (plus 21 +21)))' => 1,
      '(and (not (many num)) (eq num (minus -100 -142)))' => 1,
      '(and (one num) (eq num (times 7 6)))' => 1,
      '(and (one pi) (eq pi (div -6.28 -2)))' => 1,
      '(gt (size num) 2)' => 1,
      '(matches name "^[a-z]+$")' => 1,
      '(lt (size num) 2)' => 2,
      '(eq (size _hello) 0)' => 3,
      '(eq num pi)' => 0,
      '(absent time)' => 2,
      '(eq pi (agg (eq num 0) (sum pi)))' => 1,
      '(eq num (agg (exists oops) (count)))' => 2,
      '(lt num (agg (eq num 0) (max pi)))' => 2,
      '(eq time (min time))' => 1,
      '(and (absent time) (exists pi))' => 1,
      "(and (exists time) (not (\t\texists pi)))" => 1,
      "(or (eq num +66) (lt time #{(Time.now - 200).utc.iso8601}))" => 1
    }.each do |q, r|
      assert_equal(r, Factbase::Query.new(maps, Mutex.new, q).each.to_a.size, q)
    end
  end

  def test_simple_parsing_with_time
    maps = []
    now = Time.now.utc
    maps << { 'foo' => now }
    q = Factbase::Query.new(maps, Mutex.new, "(eq foo #{now.iso8601})")
    assert_equal(1, q.each.to_a.size)
  end

  def test_simple_deleting
    maps = []
    maps << { 'foo' => [42] }
    maps << { 'bar' => [4, 5] }
    maps << { 'bar' => 5 }
    q = Factbase::Query.new(maps, Mutex.new, '(eq bar 5)')
    assert_equal(2, q.delete!)
    assert_equal(1, maps.size)
  end

  def test_deleting_nothing
    maps = []
    maps << { 'foo' => [42] }
    maps << { 'bar' => [4, 5] }
    maps << { 'bar' => 5 }
    q = Factbase::Query.new(maps, Mutex.new, '(never)')
    assert_equal(0, q.delete!)
    assert_equal(3, maps.size)
  end

  def test_to_array
    maps = []
    maps << { 'foo' => [42] }
    assert_equal(1, Factbase::Query.new(maps, Mutex.new, '(eq foo 42)').each.to_a.size)
  end

  def test_returns_int
    maps = []
    maps << { 'foo' => 1 }
    q = Factbase::Query.new(maps, Mutex.new, '(eq foo 1)')
    assert_equal(1, q.each(&:to_s))
  end
end
