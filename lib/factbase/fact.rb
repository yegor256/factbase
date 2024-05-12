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

require_relative '../factbase'

# Fact.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Fact
  def initialize(mutex, map)
    @mutex = mutex
    @map = map
  end

  def method_missing(*args)
    k = args[0].to_s
    if k.end_with?('=')
      kk = k[0..-2]
      raise "Invalid prop name '#{kk}'" unless kk.match?(/^[a-z][a-zA-Z0-9]+$/)
      @mutex.synchronize do
        @map[kk] = [] if @map[kk].nil?
        @map[kk] << args[1]
      end
      nil
    elsif k == '[]'
      kk = args[1].to_s
      @mutex.synchronize do
        @map[kk] = [] if @map[kk].nil?
      end
      @map[kk]
    else
      v = @map[k]
      raise "Can't find '#{k}'" if v.nil?
      v[0]
    end
  end

  # rubocop:disable Style/OptionalBooleanParameter
  def respond_to?(_method, _include_private = false)
    # rubocop:enable Style/OptionalBooleanParameter
    true
  end

  def respond_to_missing?(_method, _include_private = false)
    true
  end
end
