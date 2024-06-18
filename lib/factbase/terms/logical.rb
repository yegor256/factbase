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

# Logical terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
module Factbase::Term::Logical
  def always(_fact, _maps)
    assert_args(0)
    true
  end

  def never(_fact, _maps)
    assert_args(0)
    false
  end

  def not(fact, maps)
    assert_args(1)
    !only_bool(the_values(0, fact, maps), 0)
  end

  def or(fact, maps)
    (0..@operands.size - 1).each do |i|
      return true if only_bool(the_values(i, fact, maps), i)
    end
    false
  end

  def and(fact, maps)
    (0..@operands.size - 1).each do |i|
      return false unless only_bool(the_values(i, fact, maps), i)
    end
    true
  end

  def and_or_simplify
    strs = []
    ops = []
    @operands.each do |o|
      o = o.simplify
      s = o.to_s
      next if strs.include?(s)
      strs << s
      ops << o
    end
    return ops[0] if ops.size == 1
    Factbase::Term.new(@op, ops)
  end

  def and_simplify
    and_or_simplify
  end

  def or_simplify
    and_or_simplify
  end

  def when(fact, maps)
    assert_args(2)
    a = @operands[0]
    b = @operands[1]
    !a.evaluate(fact, maps) || (a.evaluate(fact, maps) && b.evaluate(fact, maps))
  end
end
