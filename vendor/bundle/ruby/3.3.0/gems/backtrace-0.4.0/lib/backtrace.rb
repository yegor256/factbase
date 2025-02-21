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

# Backtrace as a string.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2023 Yegor Bugayenko
# License:: MIT
class Backtrace
  def initialize(exp, mine: '')
    @exp = exp
    @mine = (mine.is_a?(Regexp) ? mine : Regexp.new(Regexp.quote(mine)))
  end

  def to_s
    [
      @exp.class.name,
      ': ',
      @exp.message,
      "\n\t",
      @exp.backtrace.reverse
        .drop_while { |t| @mine.match(t).nil? }
        .reverse.join("\n\t")
    ].join
  end

  def self.exec(swallow: false, log: nil, mine: '')
    yield
  rescue StandardError => e
    trace = Backtrace.new(e, mine: mine).to_s
    if log.nil? || !log.respond_to?(:error)
      puts trace
    else
      log.error(trace)
    end
    raise e unless swallow
  end
end
