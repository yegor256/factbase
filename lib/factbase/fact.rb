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

require 'json'
require 'time'
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

  # Convert it to a string.
  # @return [String] String representation of it (in JSON)
  def to_s
    @map.to_json
  end

  # When a method is missing, this method is called.
  def method_missing(*args)
    k = args[0].to_s
    if k.end_with?('=')
      kk = k[0..-2]
      raise "Invalid prop name '#{kk}'" unless kk.match?(/^[a-z][_a-zA-Z0-9]*$/)
      raise "Prohibited prop name '#{kk}'" if kk == 'to_s'
      v = args[1]
      raise "Prop value can't be nil" if v.nil?
      raise "Prop value can't be empty" if v == ''
      raise "Prop type '#{v.class}' is not allowed" unless [String, Integer, Float, Time].include?(v.class)
      v = v.utc if v.is_a?(Time)
      @mutex.synchronize do
        before = @map[kk]
        return if before == v
        if before.nil?
          @map[kk] = v
          return
        end
        @map[kk] = [@map[kk]] unless @map[kk].is_a?(Array)
        @map[kk] << v
      end
      nil
    elsif k == '[]'
      @map[args[1].to_s]
    else
      v = @map[k]
      if v.nil?
        raise "Can't get '#{k}', the fact is empty" if @map.empty?
        raise "Can't find '#{k}' attribute in [#{@map.keys.join(', ')}]"
      end
      v.is_a?(Array) ? v[0] : v
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
