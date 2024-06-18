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

# Math terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
module Factbase::Term::Math
  def plus(fact, maps)
    arithmetic(:+, fact, maps)
  end

  def minus(fact, maps)
    arithmetic(:-, fact, maps)
  end

  def times(fact, maps)
    arithmetic(:*, fact, maps)
  end

  def div(fact, maps)
    arithmetic(:/, fact, maps)
  end

  def zero(fact, maps)
    assert_args(1)
    vv = the_values(0, fact, maps)
    return false if vv.nil?
    vv.any? { |v| (v.is_a?(Integer) || v.is_a?(Float)) && v.zero? }
  end

  def eq(fact, maps)
    cmp(:==, fact, maps)
  end

  def lt(fact, maps)
    cmp(:<, fact, maps)
  end

  def gt(fact, maps)
    cmp(:>, fact, maps)
  end

  def cmp(op, fact, maps)
    assert_args(2)
    lefts = the_values(0, fact, maps)
    return false if lefts.nil?
    rights = the_values(1, fact, maps)
    return false if rights.nil?
    lefts.any? do |l|
      l = l.floor if l.is_a?(Time) && op == :==
      rights.any? do |r|
        r = r.floor if r.is_a?(Time) && op == :==
        l.send(op, r)
      end
    end
  end

  def arithmetic(op, fact, maps)
    assert_args(2)
    lefts = the_values(0, fact, maps)
    return nil if lefts.nil?
    raise 'Too many values at first position, one expected' unless lefts.size == 1
    rights = the_values(1, fact, maps)
    return nil if rights.nil?
    raise 'Too many values at second position, one expected' unless rights.size == 1
    lefts[0].send(op, rights[0])
  end
end
