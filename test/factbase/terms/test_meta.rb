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

# Meta test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestMeta < Minitest::Test
  def test_exists
    t = Factbase::Term.new(:exists, [:foo])
    assert(t.evaluate(fact('foo' => 41), []))
    refute(t.evaluate(fact('bar' => 41), []))
  end

  def test_absent
    t = Factbase::Term.new(:absent, [:foo])
    refute(t.evaluate(fact('foo' => 41), []))
    assert(t.evaluate(fact('bar' => 41), []))
  end

  def test_size
    t = Factbase::Term.new(:size, [:foo])
    assert_equal(1, t.evaluate(fact('foo' => 41), []))
    assert_equal(0, t.evaluate(fact('foo' => nil), []))
    assert_equal(4, t.evaluate(fact('foo' => [1, 2, 3, 4]), []))
  end

  def test_type
    t = Factbase::Term.new(:type, [:foo])
    assert_equal("nil", t.evaluate(fact('foo' => nil), []))
    assert_equal("Integer", t.evaluate(fact('foo' => [1]), []))
    assert_equal("Array", t.evaluate(fact('foo' => [1, 2]), []))
    assert_equal("String", t.evaluate(fact('foo' => 'bar'), []))
  end

  def test_nil
    t = Factbase::Term.new(:nil, [:foo])
    assert(t.evaluate(fact('foo' => nil), []))
    refute(t.evaluate(fact('foo' => true), []))
    refute(t.evaluate(fact('foo' => 'bar'), []))
  end

  def test_many
    t = Factbase::Term.new(:many, [:foo])
    refute(t.evaluate(fact('foo' => nil), []))
    refute(t.evaluate(fact('foo' => 1), []))
    refute(t.evaluate(fact('foo' => "1234"), []))
    assert(t.evaluate(fact('foo' => [1, 3, 5]), []))
  end

  def test_one
    t = Factbase::Term.new(:one, [:foo])
    assert(t.evaluate(fact('foo' => 1), []))
    assert(t.evaluate(fact('foo' => "1234"), []))
    assert(t.evaluate(fact('foo' => [1]), []))
    refute(t.evaluate(fact('foo' => nil), []))
    refute(t.evaluate(fact('foo' => [1, 3, 5]), []))
  end
end
