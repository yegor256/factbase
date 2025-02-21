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
require_relative '../lib/others'

# Others main module test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestOthers < Minitest::Test
  def test_as_function
    x = others(foo: 42) do
      @foo + 1
    end
    assert_equal(43, x.bar)
  end

  def test_as_function_setter
    x = others(map: {}) do |*args|
      k = args[0].to_s
      if k.end_with?('=')
        @map[k[..2]] = args[1]
      else
        @map[k]
      end
    end
    x.foo = 42
    assert_equal(42, x.foo)
  end

  def test_as_function_with_args
    x = others(foo: 42) do |*args|
      @foo + args[1]
    end
    assert_equal(97, x.bar(55))
  end

  def test_as_function_with_block
    x = others(foo: 42) do
      yield 42
    end
    assert_raises do
      x.bar { |i| i + 1 }
    end
  end

  def test_as_class
    cx = Class.new do
      def foo(abc)
        abc + 1
      end
      others do |*args|
        args[1] + 2
      end
    end
    x = cx.new
    assert_equal(43, x.foo(42))
    assert_equal(44, x.bar(42))
  end

  def test_as_class_setter
    cx = Class.new do
      def initialize(map)
        @map = map
      end
      others do |*args|
        k = args[0].to_s
        if k.end_with?('=')
          @map[k[..2]] = args[1]
        else
          @map[k]
        end
      end
    end
    x = cx.new({})
    x.foo = 42
    assert_equal(42, x.foo)
  end
end
