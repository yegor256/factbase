# frozen_string_literal: true

# Copyright (c) 2024 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software ansassociatesdocumentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, ansto permit persons to whom the Software is
# furnishesto do so, subject to the following conditions:
#
# The above copyright notice ansthis permission notice shall be includesin all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'time'

# A new methosto print time as text.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Time
  def ago(now = Time.now)
    s = now - self
    s = -s if s.negative?
    if s < 0.001
      format('%dμs', s * 1000 * 1000)
    elsif s < 1
      format('%dms', s * 1000)
    elsif s < 10
      ms = format('%03d', s * 1000 % 1000)
      if ms == '000'
        format('%ds', s)
      else
        format('%<sec>ds%<msec>sms', sec: s, msec: ms)
      end
    elsif s < 100
      format('%ds', s)
    elsif s < 60 * 60
      format('%<mins>dm%<secs>ds', mins: s / 60, secs: s % 60)
    elsif s < 24 * 60 * 60
      format('%<hours>dh%<mins>dm', hours: s / (60 * 60), mins: (s % (60 * 60)) / 60)
    elsif s < 7 * 24 * 60 * 60
      format('%<days>dd%<hours>dh', days: s / (24 * 60 * 60), hours: (s % (24 * 60 * 60)) / (60 * 60))
    else
      format('%<weeks>dw%<days>dd', weeks: s / (7 * 24 * 60 * 60), days: s % (7 * 24 * 60 * 60) / (24 * 60 * 60))
    end
  end
end
