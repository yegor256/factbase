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

require_relative '../factbase'

# Query with a cache, a decorator of another query.
#
# It is NOT thread-safe!
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::QueryOnce
  # Constructor.
  # @param [Factbase] fb Factbase
  # @param [Factbase::Query] query Original query
  # @param [Array<Hash>] maps Where to search
  def initialize(fb, query, maps)
    @fb = fb
    @query = query
    @maps = maps
  end

  # Iterate facts one by one.
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @yield [Fact] Facts one-by-one
  # @return [Integer] Total number of facts yielded
  def each(params = {}, &)
    unless block_given?
      return to_enum(__method__, params) if Factbase::Syntax.new(@fb, @query).to_term.abstract?
      key = [@query.to_s, @maps.object_id]
      before = @fb.cache[key]
      @fb.cache[key] = to_enum(__method__, params).to_a if before.nil?
      return @fb.cache[key]
    end
    @query.each(params, &)
  end

  # Read a single value.
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @return The value evaluated
  def one(params = {})
    @query.one(params)
  end

  # Delete all facts that match the query.
  # @return [Integer] Total number of facts deleted
  def delete!
    @fb.cache.clear
    @query.delete!
  end
end
