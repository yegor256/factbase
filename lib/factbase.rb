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
#
# This is an entry point to a factbase:
#
#  fb = Factbase.new
#  f = fb.insert # new fact created
#  f.name = 'Jeff Lebowski'
#  f.age = 42
#  found = f.query('(gt 20 age)').each.to_a[0]
#  assert(found.age == 42)
#
# A factbase may be exported to a file and then imported back:
#
#  fb1 = Factbase.new
#  File.writebin(file, fb1.export)
#  fb2 = Factbase.new # it's empty
#  fb2.import(File.readbin(file))
#
# It's important to use +writebin+ and +readbin+, because the content is
# a chain of bytes, not a text.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase
  # Current version of the gem (changed by .rultor.yml on every release)
  VERSION = '0.0.0'

  # Constructor.
  def initialize(facts = [])
    @maps = facts
    @mutex = Mutex.new
  end

  # Make a duplicate of this factbase.
  # @return [Factbase] A new factbase
  def dup
    Factbase.new(@maps.dup)
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
  #  (gt time 2024-03-23T03:21:43Z)
  #  (gt cost 42)
  #  (exists seenBy)
  #  (and
  #    (eq foo 42.998)
  #    (or
  #      (gt bar 200)
  #      (absent zzz)))
  #
  # @param [String] query The query to use for selections
  def query(query)
    require_relative 'factbase/query'
    Factbase::Query.new(@maps, @mutex, query)
  end

  # Run an ACID transaction, which will either modify the factbase
  # or rollback in case of an error.
  # @param [Factbase] this The factbase to use (don't provide this param)
  def txn(this = self)
    copy = this.dup
    yield copy
    @mutex.synchronize do
      after = Marshal.load(copy.export)
      after.each_with_index do |m, i|
        @maps << {} if i >= @maps.size
        m.each do |k, v|
          @maps[i][k] = v
        end
      end
    end
  end

  # Export it into a chain of bytes.
  def export
    Marshal.dump(@maps)
  end

  # Import from a chain of bytes.
  # @param [Bytes] bytes Byte array to import
  def import(bytes)
    @maps += Marshal.load(bytes)
  end
end
