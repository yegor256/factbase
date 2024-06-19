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
require_relative 'syntax'
require_relative 'fact'
require_relative 'accum'
require_relative 'tee'

# Query.
#
# This is an internal class, it is not supposed to be instantiated directly. It
# is created by the +query()+ method of the +Factbase+ class.
#
# It is NOT thread-safe!
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Query
  # Constructor.
  # @param [Array<Fact>] maps Array of facts to start with
  # @param [Mutex] mutex Mutex to sync all modifications to the +maps+
  # @param [String] query The query as a string
  def initialize(maps, mutex, query)
    @maps = maps
    @mutex = mutex
    @query = query
  end

  # Iterate facts one by one.
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @yield [Fact] Facts one-by-one
  # @return [Integer] Total number of facts yielded
  def each(params = {})
    return to_enum(__method__, params) unless block_given?
    term = Factbase::Syntax.new(@query).to_term
    yielded = 0
    @maps.each do |m|
      extras = {}
      f = Factbase::Fact.new(@mutex, m)
      params = params.transform_keys(&:to_s) if params.is_a?(Hash)
      f = Factbase::Tee.new(f, params)
      a = Factbase::Accum.new(f, extras, false)
      r = term.evaluate(a, @maps)
      unless r.is_a?(TrueClass) || r.is_a?(FalseClass)
        raise "Unexpected evaluation result (#{r.class}), must be Boolean at #{@query}"
      end
      next unless r
      yield Factbase::Accum.new(f, extras, true)
      yielded += 1
    end
    yielded
  end

  # Read a single value.
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @return The value evaluated
  def one(params = {})
    term = Factbase::Syntax.new(@query).to_term
    params = params.transform_keys(&:to_s) if params.is_a?(Hash)
    term.evaluate(Factbase::Tee.new(nil, params), @maps)
  end

  # Delete all facts that match the query.
  # @return [Integer] Total number of facts deleted
  def delete!
    term = Factbase::Syntax.new(@query).to_term
    deleted = 0
    @mutex.synchronize do
      @maps.delete_if do |m|
        f = Factbase::Fact.new(@mutex, m)
        if term.evaluate(f, @maps)
          deleted += 1
          true
        else
          false
        end
      end
    end
    deleted
  end
end
