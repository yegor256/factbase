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
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/tuples'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestTuples < Minitest::Test
  def test_passes_facts
    fb = Factbase.new
    f1 = fb.insert
    f1.foo = 42
    f2 = fb.insert
    f2.bar = 55
    Factbase::Tuples.new(fb, ['(exists foo)', '(exists bar)']).each do |a, b|
      assert_equal(42, a.foo)
      assert_equal(55, b.bar)
    end
  end

  def test_with_empty_list_of_queries
    fb = Factbase.new
    f1 = fb.insert
    f1.foo = 42
    tuples = Factbase::Tuples.new(fb, [])
    assert(tuples.each.to_a.empty?)
  end

  def test_is_reusable
    fb = Factbase.new
    f1 = fb.insert
    f1.foo = 42
    tuples = Factbase::Tuples.new(fb, ['(exists foo)'])
    assert_equal(1, tuples.each.to_a.size)
    assert_equal(1, tuples.each.to_a.size)
  end

  def test_with_modifications
    fb = Factbase.new
    f1 = fb.insert
    f1.foo = 42
    Factbase::Tuples.new(fb, ['(exists foo)']).each do |fs|
      fs[0].bar = 1
    end
    assert_equal(1, fb.query('(exists bar)').each.to_a.size)
  end

  def test_with_txn
    fb = Factbase.new
    f1 = fb.insert
    f1.foo = 42
    Factbase::Tuples.new(fb, ['(exists foo)']).each do |fs|
      fb.txn do |fbt|
        f = fbt.insert
        f.bar = 1
      end
      fs[0].xyz = 'hey'
    end
    assert_equal(1, fb.query('(exists bar)').each.to_a.size)
    assert_equal(1, fb.query('(exists xyz)').each.to_a.size)
  end

  def test_with_chaining
    fb = Factbase.new
    f1 = fb.insert
    f1.name = 'Jeff'
    f1.friend = 'Walter'
    f2 = fb.insert
    f2.name = 'Walter'
    f2.group = 1
    f3 = fb.insert
    f3.name = 'Donny'
    f3.group = 1
    tuples = Factbase::Tuples.new(
      fb, ['(eq name "Jeff")', '(eq name "{f0.friend}")', '(eq group {f1.group})']
    )
    tuples.each do |fs|
      assert_equal('Walter', fs[1].name)
      assert(%w[Walter Donny].include?(fs[2].name))
    end
    assert_equal(2, tuples.each.to_a.size)
  end
end
