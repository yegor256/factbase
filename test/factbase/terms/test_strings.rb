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

require 'minitest/autorun'
require_relative '../../../lib/factbase/term'

# Strings test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestStrings < Minitest::Test
  def test_regexp_matching
    t = Factbase::Term.new(Factbase.new, :matches, [:foo, '[a-z]+'])
    assert(t.evaluate(fact('foo' => 'hello'), []))
    assert(t.evaluate(fact('foo' => 'hello 42'), []))
    refute(t.evaluate(fact('foo' => 42), []))
  end

  def test_concat
    t = Factbase::Term.new(Factbase.new, :concat, [42, 'hi', 3.14, :hey, Time.now])
    s = t.evaluate(fact, [])
    assert(s.start_with?('42hi3.14'))
  end

  def test_concat_empty
    t = Factbase::Term.new(Factbase.new, :concat, [])
    assert_equal('', t.evaluate(fact, []))
  end

  def test_sprintf
    t = Factbase::Term.new(Factbase.new, :sprintf, ['hi, %s!', 'Jeff'])
    assert_equal('hi, Jeff!', t.evaluate(fact, []))
  end
end
