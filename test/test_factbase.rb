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
require 'loog'
require_relative '../lib/factbase'

# Factbase main module test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestFactbase < Minitest::Test
  def test_simple_setting
    fb = Factbase.new
    fb.insert
    fb.insert.bar = 88
    found = 0
    fb.query('(exists bar)').each do |f|
      assert(42, f.bar.positive?)
      f.foo = 42
      assert_equal(42, f.foo)
      found += 1
    end
    assert_equal(1, found)
    assert_equal(2, fb.size)
  end

  def test_serialize_and_deserialize
    f1 = Factbase.new
    f2 = Factbase.new
    f1.insert.foo = 42
    Tempfile.open do |f|
      File.write(f.path, f1.export)
      f2.import(File.read(f.path))
    end
    assert_equal(1, f2.query('(eq foo 42)').each.to_a.count)
  end

  def test_empty_or_not
    fb = Factbase.new
    assert_equal(0, fb.size)
    fb.insert
    assert_equal(1, fb.size)
  end

  def test_makes_duplicate
    fb1 = Factbase.new
    fb1.insert
    assert_equal(1, fb1.size)
    fb2 = fb1.dup
    fb2.insert
    assert_equal(1, fb1.size)
    assert_equal(2, fb2.size)
  end

  def test_run_txn
    fb = Factbase.new
    fb.txn do |fbt|
      fbt.insert.bar = 42
      fbt.insert.z = 42
    end
    assert_equal(2, fb.size)
    assert(
      assert_raises do
        fb.txn do |fbt|
          fbt.insert.foo = 42
          throw 'intentionally'
        end
      end.message.include?('intentionally')
    )
    assert_equal(2, fb.size)
  end

  def test_run_txn_with_inv
    fb = Factbase::Inv.new(Factbase.new) { |_p, v| throw 'oops' if v == 42 }
    fb.insert.bar = 3
    fb.insert.foo = 5
    assert_equal(2, fb.size)
    assert(
      assert_raises do
        fb.txn do |fbt|
          fbt.insert.foo = 42
        end
      end.message.include?('oops')
    )
    assert_equal(2, fb.size)
  end

  def test_all_decorators
    [
      Factbase::Rules.new(Factbase.new, '(always)'),
      Factbase::Inv.new(Factbase.new) { |_, _| true },
      Factbase::Pre.new(Factbase.new) { |_| true },
      Factbase::Looged.new(Factbase.new, Loog::NULL),
      Factbase::Spy.new(Factbase.new, 'ff')
    ].each do |d|
      f = d.insert
      f.foo = 42
      d.txn do |fbt|
        fbt.insert.bar = 455
      end
      assert_raises do
        d.txn do |fbt|
          fbt.insert
          throw 'oops'
        end
      end
      d.import(d.export)
      assert_equal(4, d.size)
      assert_equal(4, d.query('(always)').each.to_a.size)
    end
  end
end
