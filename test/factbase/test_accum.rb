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
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/accum'
require_relative '../../lib/factbase/fact'

# Accum test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestAccum < Minitest::Test
  def test_holds_props
    map = {}
    f = Factbase::Fact.new(Factbase.new, Mutex.new, map)
    props = {}
    a = Factbase::Accum.new(f, props, false)
    a.foo = 42
    assert_raises(StandardError) { f.foo }
    assert_equal(42, a.foo)
    assert_equal([42], props['foo'])
  end

  def test_passes_props
    map = {}
    f = Factbase::Fact.new(Factbase.new, Mutex.new, map)
    props = {}
    a = Factbase::Accum.new(f, props, true)
    a.foo = 42
    assert_equal(42, f.foo)
    assert_equal(42, a.foo)
    assert_equal([42], props['foo'])
  end

  def test_appends_props
    map = {}
    f = Factbase::Fact.new(Factbase.new, Mutex.new, map)
    f.foo = 42
    props = {}
    a = Factbase::Accum.new(f, props, false)
    a.foo = 55
    assert_equal(2, a['foo'].size)
  end

  def test_empties
    f = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    a = Factbase::Accum.new(f, {}, false)
    assert_nil(a['foo'])
  end

  def test_prints_to_string
    map = {}
    f = Factbase::Fact.new(Factbase.new, Mutex.new, map)
    props = {}
    a = Factbase::Accum.new(f, props, true)
    a.foo = 42
    assert_equal('[ foo: [42] ]', f.to_s)
  end
end
