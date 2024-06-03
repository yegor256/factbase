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
    t = Factbase::Term.new(:eq, [:foo, 42])
    assert(t.evaluate(fact('foo' => [42]), []))
    assert(!t.evaluate(fact('foo' => 'Hello!'), []))
    assert(!t.evaluate(fact('bar' => ['Hello!']), []))
  end

  def test_eq_matching
    t = Factbase::Term.new(:eq, [:foo, 42])
    assert(t.evaluate(fact('foo' => 42), []))
    assert(t.evaluate(fact('foo' => [10, 5, 6, -8, 'hey', 42, 9, 'fdsf']), []))
    assert(!t.evaluate(fact('foo' => [100]), []))
    assert(!t.evaluate(fact('foo' => []), []))
    assert(!t.evaluate(fact('bar' => []), []))
  end

  def test_eq_matching_time
    now = Time.now
    t = Factbase::Term.new(:eq, [:foo, Time.parse(now.iso8601)])
    assert(t.evaluate(fact('foo' => now), []))
    assert(t.evaluate(fact('foo' => [now, Time.now]), []))
  end

  def test_lt_matching
    t = Factbase::Term.new(:lt, [:foo, 42])
    assert(t.evaluate(fact('foo' => [10]), []))
    assert(!t.evaluate(fact('foo' => [100]), []))
    assert(!t.evaluate(fact('foo' => 100), []))
    assert(!t.evaluate(fact('bar' => 100), []))
  end

  def test_gt_matching
    t = Factbase::Term.new(:gt, [:foo, 42])
    assert(t.evaluate(fact('foo' => [100]), []))
    assert(t.evaluate(fact('foo' => 100), []))
    assert(!t.evaluate(fact('foo' => [10]), []))
    assert(!t.evaluate(fact('foo' => 10), []))
    assert(!t.evaluate(fact('bar' => 10), []))
  end

  def test_lt_matching_time
    t = Factbase::Term.new(:lt, [:foo, Time.now])
    assert(t.evaluate(fact('foo' => [Time.now - 100]), []))
    assert(!t.evaluate(fact('foo' => [Time.now + 100]), []))
    assert(!t.evaluate(fact('bar' => [100]), []))
  end

  def test_gt_matching_time
    t = Factbase::Term.new(:gt, [:foo, Time.now])
    assert(t.evaluate(fact('foo' => [Time.now + 100]), []))
    assert(!t.evaluate(fact('foo' => [Time.now - 100]), []))
    assert(!t.evaluate(fact('bar' => [100]), []))
  end

  def test_false_matching
    t = Factbase::Term.new(:never, [])
    assert(!t.evaluate(fact('foo' => [100]), []))
  end

  def test_not_matching
    t = Factbase::Term.new(:not, [Factbase::Term.new(:always, [])])
    assert(!t.evaluate(fact('foo' => [100]), []))
  end

  def test_not_eq_matching
    t = Factbase::Term.new(:not, [Factbase::Term.new(:eq, [:foo, 100])])
    assert(t.evaluate(fact('foo' => [42, 12, -90]), []))
    assert(!t.evaluate(fact('foo' => 100), []))
  end

  def test_size_matching
    t = Factbase::Term.new(:size, [:foo])
    assert_equal(3, t.evaluate(fact('foo' => [42, 12, -90]), []))
    assert_equal(0, t.evaluate(fact('bar' => 100), []))
  end

  def test_exists_matching
    t = Factbase::Term.new(:exists, [:foo])
    assert(t.evaluate(fact('foo' => [42, 12, -90]), []))
    assert(!t.evaluate(fact('bar' => 100), []))
  end

  def test_absent_matching
    t = Factbase::Term.new(:absent, [:foo])
    assert(t.evaluate(fact('z' => [42, 12, -90]), []))
    assert(!t.evaluate(fact('foo' => 100), []))
  end

  def test_type_matching
    t = Factbase::Term.new(:type, [:foo])
    assert_equal('Integer', t.evaluate(fact('foo' => 42), []))
    assert_equal('Array', t.evaluate(fact('foo' => [1, 2, 3]), []))
    assert_equal('String', t.evaluate(fact('foo' => 'Hello, world!'), []))
    assert_equal('Float', t.evaluate(fact('foo' => 3.14), []))
    assert_equal('Time', t.evaluate(fact('foo' => Time.now), []))
    assert_equal('nil', t.evaluate(fact, []))
  end

  def test_regexp_matching
    t = Factbase::Term.new(:matches, [:foo, '[a-z]+'])
    assert(t.evaluate(fact('foo' => 'hello'), []))
    assert(t.evaluate(fact('foo' => 'hello 42'), []))
    assert(!t.evaluate(fact('foo' => 42), []))
  end

  def test_or_matching
    t = Factbase::Term.new(
      :or,
      [
        Factbase::Term.new(:eq, [:foo, 4]),
        Factbase::Term.new(:eq, [:bar, 5])
      ]
    )
    assert(t.evaluate(fact('foo' => [4]), []))
    assert(t.evaluate(fact('bar' => [5]), []))
    assert(!t.evaluate(fact('bar' => [42]), []))
  end

  def test_when_matching
    t = Factbase::Term.new(
      :when,
      [
        Factbase::Term.new(:eq, [:foo, 4]),
        Factbase::Term.new(:eq, [:bar, 5])
      ]
    )
    assert(t.evaluate(fact('foo' => 4, 'bar' => 5), []))
    assert(!t.evaluate(fact('foo' => 4), []))
    assert(t.evaluate(fact('foo' => 5, 'bar' => 5), []))
  end

  def test_defn_simple
    t = Factbase::Term.new(:defn, [:foo, 'self.to_s'])
    assert_equal(true, t.evaluate(fact('foo' => 4), []))
    t1 = Factbase::Term.new(:foo, ['hello, world!'])
    assert_equal('(foo \'hello, world!\')', t1.evaluate(fact, []))
  end

  def test_defn_again_by_mistake
    t = Factbase::Term.new(:defn, [:and, 'self.to_s'])
    assert_raises do
      t.evaluate(fact, [])
    end
  end

  def test_defn_bad_name_by_mistake
    t = Factbase::Term.new(:defn, [:to_s, 'self.to_s'])
    assert_raises do
      t.evaluate(fact, [])
    end
  end

  def test_past
    t = Factbase::Term.new(:prev, [:foo])
    assert_nil(t.evaluate(fact('foo' => 4), []))
    assert_equal([4], t.evaluate(fact('foo' => 5), []))
  end

  def test_at
    t = Factbase::Term.new(:at, [1, :foo])
    assert_nil(t.evaluate(fact('foo' => 4), []))
    assert_equal(5, t.evaluate(fact('foo' => [4, 5]), []))
  end

  def test_either
    t = Factbase::Term.new(:either, [Factbase::Term.new(:at, [5, :foo]), 42])
    assert_equal([42], t.evaluate(fact('foo' => 4), []))
  end

  def test_report_missing_term
    t = Factbase::Term.new(:something, [])
    msg = assert_raises do
      t.evaluate(fact, [])
    end.message
    assert(msg.include?('not defined at (something)'), msg)
  end

  def test_report_other_error
    t = Factbase::Term.new(:at, [])
    msg = assert_raises do
      t.evaluate(fact, [])
    end.message
    assert(msg.include?('at (at)'), msg)
  end

  private

  def fact(map = {})
    Factbase::Fact.new(Mutex.new, map)
  end
end
