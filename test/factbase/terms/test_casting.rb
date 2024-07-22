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
  def test_to_str
    t = Factbase::Term.new(:to_string, [Time.now])
    assert_equal('String', t.evaluate(fact, []).class.to_s)
  end

  def test_to_integer
    t = Factbase::Term.new(:to_integer, [[42, 'hello']])
    assert_equal('Integer', t.evaluate(fact, []).class.to_s)
  end

  def test_to_float
    t = Factbase::Term.new(:to_float, [[3.14, 'hello']])
    assert_equal('Float', t.evaluate(fact, []).class.to_s)
  end

  def test_to_time
    t = Factbase::Term.new(:to_time, [%w[2023-01-01 hello]])
    assert_equal('Time', t.evaluate(fact, []).class.to_s)
  end

  private

  def fact(map = {})
    Factbase::Fact.new(Mutex.new, map)
  end
end
