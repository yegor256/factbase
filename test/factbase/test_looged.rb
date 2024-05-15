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
require_relative '../../lib/factbase/looged'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestLooged < Minitest::Test
  def test_simple_setting
    fb = Factbase::Looged.new(Factbase.new, Loog::NULL)
    fb.insert
    fb.insert.bar = 3
    found = 0
    fb.query('(exists id)').each do |f|
      assert(42, f.id.positive?)
      f.foo = 42
      assert_equal(42, f.foo)
      found += 1
    end
    assert_equal(2, found)
    assert_equal(2, fb.size)
  end

  def test_returns_int
    fb = Factbase.new
    fb.insert
    fb.insert
    assert_equal(2, Factbase::Looged.new(fb, Loog::NULL).query('()').each(&:to_s))
  end

  def test_returns_int_when_empty
    fb = Factbase.new
    assert_equal(0, Factbase::Looged.new(fb, Loog::NULL).query('()').each(&:to_s))
  end

  def test_logs_when_enumerator
    fb = Factbase::Looged.new(Factbase.new, Loog::NULL)
    assert_equal(0, fb.query('()').each.to_a.size)
    fb.insert
    assert_equal(1, fb.query('()').each.to_a.size)
  end

  def test_proper_logging
    log = Loog::Buffer.new
    fb = Factbase::Looged.new(Factbase.new, log)
    fb.insert
    fb.insert.bar = 3
    fb.insert
    fb.query('(exists bar)').each.to_a
    fb.query('(not (exists bar))').delete!
    [
      'Inserted fact #1',
      'Inserted fact #2',
      'Set \'bar\' to \'"3"\' (Integer)',
      'Found 1 fact(s) by \'(exists bar)\'',
      'Deleted 2 fact(s) by \'(not (exists bar))\''
    ].each do |s|
      assert(log.to_s.include?("#{s}\n"), "#{log}\n")
    end
  end
end
