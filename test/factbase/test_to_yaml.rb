# frozen_string_literal: true

# Copyright (c) 2024-2025 Yegor Bugayenko
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
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/to_yaml'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestToYAML < Minitest::Test
  def test_simple_rendering
    fb = Factbase.new
    f = fb.insert
    f._id = 1
    f.foo = 42
    f.foo = 256
    fb.insert._id = 2
    to = Factbase::ToYAML.new(fb)
    yaml = YAML.load(to.yaml)
    assert_equal(2, yaml.size)
    assert_equal(42, yaml[0]['foo'][0])
    assert_equal(256, yaml[0]['foo'][1])
  end

  def test_sorts_keys
    fb = Factbase.new
    f = fb.insert
    f.b = 42
    f.a = 256
    f.c = 10
    yaml = Factbase::ToYAML.new(fb).yaml
    assert(yaml.include?("a: 256\n  b: 42\n  c: 10"), yaml)
  end
end
