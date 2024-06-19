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

# Tee of two facts.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Tee
  # Ctor.
  # @param [Factbase::Fact] fact Primary fact to use for reading
  # @param [Factbase::Fact] upper Fact to access with a "$" prefix
  def initialize(fact, upper)
    @fact = fact
    @upper = upper
  end

  def to_s
    @fact.to_s
  end

  def method_missing(*args)
    return @fact.method_missing(*args) unless args[0].to_s == '[]' && args[1].to_s.start_with?('$')
    n = args[1].to_s
    n = n[1..] unless @upper.is_a?(Factbase::Tee)
    @upper[n]
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
