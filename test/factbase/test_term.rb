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
require_relative '../../lib/factbase/term'

# Term test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestTerm < Minitest::Test
  def test_simple_matching
    t = Factbase::Term.new(:eq, ['foo', 42])
    assert(t.matches?(fact('foo' => [42])))
    assert(!t.matches?(fact('foo' => 'Hello!')))
    assert(!t.matches?(fact('bar' => ['Hello!'])))
  end

  def test_eq_matching
    t = Factbase::Term.new(:eq, ['foo', 42])
    assert(t.matches?(fact('foo' => 42)))
    assert(t.matches?(fact('foo' => [10, 5, 6, -8, 'hey', 42, 9, 'fdsf'])))
    assert(!t.matches?(fact('foo' => [100])))
    assert(!t.matches?(fact('foo' => [])))
    assert(!t.matches?(fact('bar' => [])))
  end

  def test_lt_matching
    t = Factbase::Term.new(:lt, ['foo', 42])
    assert(t.matches?(fact('foo' => [10])))
    assert(!t.matches?(fact('foo' => [100])))
    assert(!t.matches?(fact('foo' => 100)))
    assert(!t.matches?(fact('bar' => 100)))
  end

  def test_gt_matching
    t = Factbase::Term.new(:gt, ['foo', 42])
    assert(t.matches?(fact('foo' => [100])))
    assert(t.matches?(fact('foo' => 100)))
    assert(!t.matches?(fact('foo' => [10])))
    assert(!t.matches?(fact('foo' => 10)))
    assert(!t.matches?(fact('bar' => 10)))
  end

  def test_lt_matching_time
    t = Factbase::Term.new(:lt, ['foo', Time.now])
    assert(t.matches?(fact('foo' => [Time.now - 100])))
    assert(!t.matches?(fact('foo' => [Time.now + 100])))
    assert(!t.matches?(fact('bar' => [100])))
  end

  def test_gt_matching_time
    t = Factbase::Term.new(:gt, ['foo', Time.now])
    assert(t.matches?(fact('foo' => [Time.now + 100])))
    assert(!t.matches?(fact('foo' => [Time.now - 100])))
    assert(!t.matches?(fact('bar' => [100])))
  end

  def test_not_matching
    t = Factbase::Term.new(:not, [Factbase::Term.new(:nil, [])])
    assert(!t.matches?(fact('foo' => [100])))
  end

  def test_not_eq_matching
    t = Factbase::Term.new(:not, [Factbase::Term.new(:eq, ['foo', 100])])
    assert(t.matches?(fact('foo' => [42, 12, -90])))
    assert(!t.matches?(fact('foo' => 100)))
  end

  def test_exists_matching
    t = Factbase::Term.new(:exists, ['foo'])
    assert(t.matches?(fact('foo' => [42, 12, -90])))
    assert(!t.matches?(fact('bar' => 100)))
  end

  def test_absent_matching
    t = Factbase::Term.new(:absent, ['foo'])
    assert(t.matches?(fact('z' => [42, 12, -90])))
    assert(!t.matches?(fact('foo' => 100)))
  end

  def test_or_matching
    t = Factbase::Term.new(
      :or,
      [
        Factbase::Term.new(:eq, ['foo', 4]),
        Factbase::Term.new(:eq, ['bar', 5])
      ]
    )
    assert(t.matches?(fact('foo' => [4])))
    assert(t.matches?(fact('bar' => [5])))
    assert(!t.matches?(fact('bar' => [42])))
  end

  private

  def fact(map)
    Factbase::Fact.new(Mutex.new, map)
  end
end
