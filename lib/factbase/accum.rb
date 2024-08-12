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

require 'others'
require_relative '../factbase'

# Accumulator of props, a decorator of +Factbase::Fact+.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Accum
  # Ctor.
  # @param [Factbase::Fact] fact The fact to decorate
  # @param [Hash] props Hash of props that were set
  # @param [Boolean] pass TRUE if all "set" operations must go through, to the +fact+
  def initialize(fact, props, pass)
    @fact = fact
    @props = props
    @pass = pass
  end

  def to_s
    "#{@fact} + #{@props}"
  end

  def all_properties
    @fact.all_properties
  end

  others do |*args|
    k = args[0].to_s
    if k.end_with?('=')
      kk = k[0..-2]
      @props[kk] = [] if @props[kk].nil?
      @props[kk] << args[1]
      @fact.method_missing(*args) if @pass
    elsif k == '[]'
      kk = args[1].to_s
      vv = @props[kk].nil? ? [] : @props[kk]
      vvv = @fact.method_missing(*args)
      vvv = [vvv] unless vvv.nil? || vvv.is_a?(Array)
      vv += vvv unless vvv.nil?
      vv.uniq!
      vv.empty? ? nil : vv
    elsif @props[k].nil?
      @fact.method_missing(*args)
    else
      @props[k][0]
    end
  end
end
