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

# Factbase.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase
  VERSION = '0.0.0'

  # Insert a new fact.
  # @param pairs [Array] List of (key,value) tuples
  # @return [Integer] The ID of the newly created fact
  def insert(pairs)
    # empty
  end

  # Update an existing fact by adding new pairs to it.
  # @param id [Integer] The ID of the fact to update
  # @param pairs [Array] List of (key,value) tuples
  def append(id, fact)
    # empty
  end

  # Iterate over facts that satisfy the condition.
  #
  # Terms in the query may be joined with "AND" and "OR". They may be groupped
  # with brackets. There is also "IS NULL" and "IS NOT NULL" operators. Examples:
  #
  # ```
  # ```
  #
  # @param query [String] The query to use for selections, e.g. "type = 'Foo'"
  def select(query)
    # empty
  end
end
