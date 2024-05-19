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
require 'yaml'

# Factbase.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase
  # Current version of the gem (changed by .rultor.yml on every release)
  VERSION = '0.0.0'

  # Constructor.
  def initialize
    @maps = []
    @mutex = Mutex.new
  end

  # Is it empty?
  # @return [Boolean] TRUE if there are no facts inside
  def empty?
    @maps.empty?
  end

  # Size.
  # @return [Integer] How many facts are in there
  def size
    @maps.size
  end

  # Insert a new fact.
  # @return [Factbase::Fact] The fact just inserted
  def insert
    require_relative 'factbase/fact'
    map = {}
    @mutex.synchronize do
      @maps << map
    end
    Factbase::Fact.new(@mutex, map)
  end

  # Create a query capable of iterating.
  #
  # There is a Lisp-like syntax, for example:
  #
  #  (eq title 'Object Thinking')
  #  (gt time '2024-03-23T03:21:43')
  #  (gt cost 42)
  #  (exists seenBy)
  #  (and
  #    (eq foo 42)
  #    (or
  #      (gt bar 200)
  #      (absent zzz)))
  #
  # @param [String] query The query to use for selections
  def query(query)
    require_relative 'factbase/query'
    Factbase::Query.new(@maps, @mutex, query)
  end

  # Export it into a chain of bytes.
  def export
    Marshal.dump(@maps)
  end

  # Import from a chain of bytes.
  def import(bytes)
    @maps += Marshal.load(bytes)
  end
end
