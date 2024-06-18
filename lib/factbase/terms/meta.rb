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

require_relative '../../factbase'

# Meta terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
module Factbase::Term::Meta
  def exists(fact, _maps)
    assert_args(1)
    !by_symbol(0, fact).nil?
  end

  def absent(fact, _maps)
    assert_args(1)
    by_symbol(0, fact).nil?
  end

  def size(fact, _maps)
    assert_args(1)
    v = by_symbol(0, fact)
    return 0 if v.nil?
    return 1 unless v.is_a?(Array)
    v.size
  end

  def type(fact, _maps)
    assert_args(1)
    v = by_symbol(0, fact)
    return 'nil' if v.nil?
    v = v[0] if v.is_a?(Array) && v.size == 1
    v.class.to_s
  end

  def nil(fact, maps)
    assert_args(1)
    the_values(0, fact, maps).nil?
  end

  def many(fact, maps)
    assert_args(1)
    v = the_values(0, fact, maps)
    !v.nil? && v.size > 1
  end

  def one(fact, maps)
    assert_args(1)
    v = the_values(0, fact, maps)
    !v.nil? && v.size == 1
  end
end
