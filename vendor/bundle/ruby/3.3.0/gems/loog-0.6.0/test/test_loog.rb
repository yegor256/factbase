# frozen_string_literal: true

# (The MIT License)
#
# Copyright (c) 2018-2024 Yegor Bugayenko
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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'minitest/autorun'
require_relative '../lib/loog'

# Loog test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2024 Yegor Bugayenko
# License:: MIT
class LoogTest < Minitest::Test
  def test_simple_logging
    Loog::VERBOSE.info('Works?')
  end

  def test_null_logging
    Loog::NULL.info('Should not be visible')
  end

  def test_buffering
    b = Loog::Buffer.new(formatter: Loog::FULL)
    b.debug('Hello, world!')
    b.info('Hello, world!')
    b.warn('Hello, world!')
    b.error('Hello, world!')
    stdout = b.to_s
    assert(stdout.include?('Hello'))
    assert(stdout.include?('DEBUG'))
  end

  def test_quiet_buffering
    b = Loog::Buffer.new
    b.info('Hey, друг!')
    b.warn('Bye!')
    b.error('+')
    assert_equal("Hey, друг!\nBye!\n+\n", b.to_s)
  end

  def test_buffer_non_utf
    b = Loog::Buffer.new
    msg = [0x41, 0x42, 0xC0].pack('c*')
    b.debug('привет')
    b.debug(msg)
    stdout = b.to_s
    assert(stdout.include?('AB'), stdout)
  end
end
