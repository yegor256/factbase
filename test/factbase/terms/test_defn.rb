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

# Defn test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestDefn < Minitest::Test
  def test_defn_simple
    t = Factbase::Term.new(Factbase.new, :defn, [:foo, 'self.to_s'])
    assert(t.evaluate(fact('foo' => 4), []))
    t1 = Factbase::Term.new(Factbase.new, :foo, ['hello, world!'])
    assert_equal('(foo \'hello, world!\')', t1.evaluate(fact, []))
  end

  def test_defn_again_by_mistake
    t = Factbase::Term.new(Factbase.new, :defn, [:and, 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [])
    end
  end

  def test_defn_bad_name_by_mistake
    t = Factbase::Term.new(Factbase.new, :defn, [:to_s, 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [])
    end
  end

  def test_defn_bad_name_spelling_by_mistake
    t = Factbase::Term.new(Factbase.new, :defn, [:'some-key', 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [])
    end
  end

  def test_undef_simple
    t = Factbase::Term.new(Factbase.new, :defn, [:hello, 'self.to_s'])
    assert(t.evaluate(fact, []))
    t = Factbase::Term.new(Factbase.new, :undef, [:hello])
    assert(t.evaluate(fact, []))
  end
end
