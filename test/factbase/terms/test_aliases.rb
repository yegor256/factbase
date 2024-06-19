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

require 'minitest/autorun'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/syntax'
require_relative '../../../lib/factbase/accum'

# Aliases test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestAliases < Minitest::Test
  def test_aliases
    maps = [
      { 'x' => [1], 'y' => [0] },
      { 'x' => [2], 'y' => [42] }
    ]
    {
      '(as foo (plus x 1))' => '(exists foo)',
      '(as foo (plus x y))' => '(gt foo 0)',
      '(as foo (plus bar 1))' => '(absent foo)'
    }.each do |q, r|
      t = Factbase::Syntax.new(q).to_term
      maps.each do |m|
        f = Factbase::Accum.new(fact(m), {}, false)
        next unless t.evaluate(f, maps)
        assert(Factbase::Syntax.new(r).to_term.evaluate(f, []), "#{q} -> #{f}")
      end
    end
  end

  def test_join
    maps = [
      { 'x' => 1, 'y' => 0, 'z' => 4 },
      { 'x' => [2], 'bar' => [44, 55, 66] }
    ]
    {
      '(join "foo_x<=x" (gt x 1))' => '(exists foo_x)',
      '(join "foo <=bar  " (exists bar))' => '(and (eq foo 44) (eq foo 55))',
      '(join "uuu <= fff" (eq fff 1))' => '(absent uuu)'
    }.each do |q, r|
      t = Factbase::Syntax.new(q).to_term
      maps.each do |m|
        f = Factbase::Accum.new(fact(m), {}, false)
        require_relative '../../../lib/factbase/looged'
        f = Factbase::Looged::Fact.new(f, Loog::NULL)
        next unless t.evaluate(f, maps)
        assert(Factbase::Syntax.new(r).to_term.evaluate(f, []), "#{q} -> #{f} doesn't match #{r}")
      end
    end
  end

  private

  def fact(map = {})
    Factbase::Fact.new(Mutex.new, map)
  end
end
