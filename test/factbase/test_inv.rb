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
require_relative '../../lib/factbase/inv'
require_relative '../../lib/factbase/pre'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestInv < Minitest::Test
  def test_simple_checking
    fb = Factbase::Inv.new(Factbase.new) do |p, v|
      raise 'oops' if v.is_a?(String) && p == 'b'
    end
    f = fb.insert
    f.a = 42
    assert_raises do
      f.b = 'here we should crash'
    end
    f.c = 256
    assert_equal(42, f.a)
  end

  def test_pre_and_inv
    fb = Factbase::Inv.new(Factbase.new) do |p, v|
      raise 'oops' if v.is_a?(String) && p == 'b'
    end
    fb = Factbase::Pre.new(fb) do |f|
      f.id = 42
    end
    f = fb.insert
    assert_equal(42, f.id)
  end
end
