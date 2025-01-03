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

require 'loog'
require 'decoor'
require_relative '../factbase'

# A decorator of a +Factbase+, that runs a provided block on every +insert+.
#
# For example, you can use this decorator if you want to put some properties
# into every fact that gets into the factbase:
#
#  fb = Factbase::Pre.new(Factbase.new) do |f, fbt|
#    f.when = Time.now
#  end
#
# The second argument passed to the block is the factbase, while the first
# one is the fact just inserted.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Pre
  decoor(:fb)

  def initialize(fb, &block)
    raise 'The "fb" is nil' if fb.nil?
    @fb = fb
    @block = block
  end

  def dup
    Factbase::Pre.new(@fb.dup, &@block)
  end

  def insert
    f = @fb.insert
    @block.call(f, self)
    f
  end

  def txn(this = self, &)
    @fb.txn(this, &)
  end
end
