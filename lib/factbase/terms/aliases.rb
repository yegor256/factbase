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

# Aliases terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
module Factbase::Term::Aliases
  def as(fact, maps)
    assert_args(2)
    a = @operands[0]
    raise "A symbol expected as first argument of 'as'" unless a.is_a?(Symbol)
    vv = the_values(1, fact, maps)
    vv&.each { |v| fact.send("#{a}=", v) }
    true
  end

  def join(fact, maps)
    assert_args(2)
    jumps = @operands[0]
    raise "A string expected as first argument of 'join'" unless jumps.is_a?(String)
    jumps = jumps.split(',')
      .map(&:strip)
      .map { |j| j.split('<=').map(&:strip) }
      .map { |j| j.size == 1 ? [j[0], j[0]] : j }
    term = @operands[1]
    raise "A term expected, but '#{term}' provided" unless term.is_a?(Factbase::Term)
    subset = Factbase::Query.new(maps, Mutex.new, term.to_s).each(fact).to_a
    subset.each do |s|
      jumps.each do |to, from|
        s[from]&.each do |v|
          fact.send("#{to}=", v)
        end
      end
    end
    true
  end
end
