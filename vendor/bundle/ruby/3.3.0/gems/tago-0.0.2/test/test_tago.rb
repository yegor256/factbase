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
require_relative '../lib/tago'

# Main test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestTago < Minitest::Test
  def test_simple_printing
    t = Time.now
    assert_equal('14ms', (t - 0.014).ago(t))
    assert_equal('1s', (t - 1).ago(t))
    assert_equal('1s350ms', (t - 1.35).ago(t))
    assert_equal('67s', (t - 67).ago(t))
    assert_equal('4m5s', (t - 245).ago(t))
    assert_equal('13h18m', (t - (13.3 * 60 * 60)).ago(t))
    assert_equal('5d0h', (t - (5 * 24 * 60 * 60)).ago(t))
    assert_equal('5d7h', (t - (5.3 * 24 * 60 * 60)).ago(t))
    assert_equal('22w1d', (t - (155 * 24 * 60 * 60)).ago(t))
  end

  def test_inverse
    t = Time.now
    assert_equal('14ms', (t + 0.014).ago(t))
    assert_equal('1s', (t + 1).ago(t))
    assert_equal('67s', (t + 67).ago(t))
    assert_equal('13h0m', (t + (13 * 60 * 60)).ago(t))
    assert_equal('5d0h', (t + (5 * 24 * 60 * 60)).ago(t))
    assert_equal('22w1d', (t + (155 * 24 * 60 * 60)).ago(t))
  end
end
