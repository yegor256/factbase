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
require_relative '../lib/decoor'

# Decoor main module test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestDecoor < Minitest::Test
  def test_object_decoration
    cy = Class.new do
      def booo
        yield 55
      end

      def zero
        0
      end
    end
    x = decoor(cy.new, bar: 42) do
      def foo
        @bar
      end

      def sum
        @origin.zero + 10
      end
    end
    assert_equal(42, x.foo)
    assert_equal(10, x.sum)
    assert_equal(56, x.booo { |v| v + 1 })
  end

  def test_class_decoration
    cy = Class.new do
      def booo
        yield 44
      end
    end
    cz = Class.new do
      decoor(:origin)

      def initialize(origin, bar: nil)
        @origin = origin
        @bar = bar
      end

      def foo
        @bar
      end
    end
    z = cz.new(cy.new, bar: 42)
    assert_equal(42, z.foo)
    assert_equal(45, z.booo { |v| v + 1 })
  end
end
