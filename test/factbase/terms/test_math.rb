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

# Math test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestMath < Minitest::Test
  def test_simple
    t = Factbase::Term.new(:eq, [:foo, 42])
    assert(t.evaluate(fact('foo' => [42]), []))
    assert(!t.evaluate(fact('foo' => 'Hello!'), []))
    assert(!t.evaluate(fact('bar' => ['Hello!']), []))
  end

  def test_zero
    t = Factbase::Term.new(:zero, [:foo])
    assert(t.evaluate(fact('foo' => [0]), []))
    assert(t.evaluate(fact('foo' => [10, 5, 6, -8, 'hey', 0, 9, 'fdsf']), []))
    assert(!t.evaluate(fact('foo' => [100]), []))
    assert(!t.evaluate(fact('foo' => []), []))
    assert(!t.evaluate(fact('bar' => []), []))
  end

  def test_eq
    t = Factbase::Term.new(:eq, [:foo, 42])
    assert(t.evaluate(fact('foo' => 42), []))
    assert(t.evaluate(fact('foo' => [10, 5, 6, -8, 'hey', 42, 9, 'fdsf']), []))
    assert(!t.evaluate(fact('foo' => [100]), []))
    assert(!t.evaluate(fact('foo' => []), []))
    assert(!t.evaluate(fact('bar' => []), []))
  end

  def test_eq_time
    now = Time.now
    t = Factbase::Term.new(:eq, [:foo, Time.parse(now.iso8601)])
    assert(t.evaluate(fact('foo' => now), []))
    assert(t.evaluate(fact('foo' => [now, Time.now]), []))
  end

  def test_lt
    t = Factbase::Term.new(:lt, [:foo, 42])
    assert(t.evaluate(fact('foo' => [10]), []))
    assert(!t.evaluate(fact('foo' => [100]), []))
    assert(!t.evaluate(fact('foo' => 100), []))
    assert(!t.evaluate(fact('bar' => 100), []))
  end

  def test_gt
    t = Factbase::Term.new(:gt, [:foo, 42])
    assert(t.evaluate(fact('foo' => [100]), []))
    assert(t.evaluate(fact('foo' => 100), []))
    assert(!t.evaluate(fact('foo' => [10]), []))
    assert(!t.evaluate(fact('foo' => 10), []))
    assert(!t.evaluate(fact('bar' => 10), []))
  end

  def test_lt_time
    t = Factbase::Term.new(:lt, [:foo, Time.now])
    assert(t.evaluate(fact('foo' => [Time.now - 100]), []))
    assert(!t.evaluate(fact('foo' => [Time.now + 100]), []))
    assert(!t.evaluate(fact('bar' => [100]), []))
  end

  def test_gt_time
    t = Factbase::Term.new(:gt, [:foo, Time.now])
    assert(t.evaluate(fact('foo' => [Time.now + 100]), []))
    assert(!t.evaluate(fact('foo' => [Time.now - 100]), []))
    assert(!t.evaluate(fact('bar' => [100]), []))
  end

  def test_plus
    t = Factbase::Term.new(:plus, [:foo, 42])
    assert_equal(46, t.evaluate(fact('foo' => 4), []))
    assert(t.evaluate(fact, []).nil?)
  end

  def test_plus_time
    t = Factbase::Term.new(:plus, [:foo, '12 days'])
    assert_equal(Time.parse('2024-01-13'), t.evaluate(fact('foo' => Time.parse('2024-01-01')), []))
    assert(t.evaluate(fact, []).nil?)
  end

  def test_minus
    t = Factbase::Term.new(:minus, [:foo, 42])
    assert_equal(58, t.evaluate(fact('foo' => 100), []))
    assert(t.evaluate(fact, []).nil?)
  end

  private

  def fact(map = {})
    Factbase::Fact.new(Mutex.new, map)
  end
end
