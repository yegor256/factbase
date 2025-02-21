# frozen_string_literal: true

# (The MIT License)
#
# Copyright (c) 2018-2023 Yegor Bugayenko
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
require_relative '../lib/backtrace'

# Backtract test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2023 Yegor Bugayenko
# License:: MIT
class BacktraceTest < Minitest::Test
  def test_prints_exception
    raise 'Just a test'
  rescue StandardError => e
    text = Backtrace.new(e).to_s
    assert(text.include?("RuntimeError: Just a test\n"), text)
    assert(text.include?('test/test_backtrace.rb'), text)
  end

  def test_runs_a_block
    log = FakeLog.new
    Backtrace.exec(swallow: true, log: log) do
      raise 'It is intended'
    end
    assert(log.sent.include?('intended'))
  end

  def test_runs_a_block_to_console
    Backtrace.exec(swallow: true, mine: 'backtrace') do
      raise 'It is intended'
    end
  end

  def test_runs_a_block_to_broken_log
    Backtrace.exec(swallow: true, log: Object.new) do
      raise 'It is intended'
    end
  end

  class FakeLog
    attr_reader :sent

    def error(msg)
      @sent = msg
    end
  end
end
