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

require_relative '../../factbase'

# String terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Term::Strings
  def concat(fact, maps)
    (0..@operands.length - 1).map { |i| the_values(i, fact, maps)&.first }.join
  end

  def sprintf(fact, maps)
    fmt = the_values(0, fact, maps)[0]
    ops = (1..@operands.length - 1).map { |i| the_values(i, fact, maps)&.first }
    format(*([fmt] + ops))
  end

  def matches(fact, maps)
    assert_args(2)
    str = the_values(0, fact, maps)
    return false if str.nil?
    raise 'Exactly one string expected' unless str.size == 1
    re = the_values(1, fact, maps)
    raise 'Regexp is nil' if re.nil?
    raise 'Exactly one regexp expected' unless re.size == 1
    str[0].to_s.match?(re[0])
  end
end
