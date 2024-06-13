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
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/looged'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestLooged < Minitest::Test
  def test_simple_setting
    fb = Factbase::Looged.new(Factbase.new, Loog::NULL)
    fb.insert
    fb.insert.bar = 3
    found = 0
    fb.query('(exists bar)').each do |f|
      assert(42, f.bar.positive?)
      f.foo = 42
      assert_equal(42, f.foo)
      found += 1
    end
    assert_equal(1, found)
    assert_equal(2, fb.size)
  end

  def test_with_txn
    log = Loog::Buffer.new
    fb = Factbase::Looged.new(Factbase.new, log)
    assert(
      fb.txn do |fbt|
        fbt.insert.foo = 42
      end
    )
    assert_equal(1, fb.size)
    assert(log.to_s.include?('modified'), log)
  end

  def test_with_txn_rollback
    log = Loog::Buffer.new
    fb = Factbase::Looged.new(Factbase.new, log)
    assert(!fb.txn { raise Factbase::Rollback })
    assert_equal(0, fb.size)
    assert(log.to_s.include?('rolled back'), log)
    assert(!log.to_s.include?('didn\'t touch'), log)
  end

  def test_with_modifying_txn
    log = Loog::Buffer.new
    fb = Factbase::Looged.new(Factbase.new, log)
    fb.insert.foo = 1
    assert(!fb.txn { |fbt| fbt.query('(always)').each.to_a }, log)
    assert(fb.txn { |fbt| fbt.query('(always)').each.to_a[0].foo = 42 }, log)
    assert(log.to_s.include?('modified'), log)
  end

  def test_with_empty_txn
    log = Loog::Buffer.new
    fb = Factbase::Looged.new(Factbase.new, log)
    assert(!fb.txn { |fbt| fbt.query('(always)').each.to_a })
    assert(log.to_s.include?('didn\'t touch'), log)
  end

  def test_returns_int
    fb = Factbase.new
    fb.insert
    fb.insert
    assert_equal(2, Factbase::Looged.new(fb, Loog::NULL).query('(always)').each(&:to_s))
  end

  def test_returns_int_when_empty
    fb = Factbase.new
    assert_equal(0, Factbase::Looged.new(fb, Loog::NULL).query('(always)').each(&:to_s))
  end

  def test_logs_when_enumerator
    fb = Factbase::Looged.new(Factbase.new, Loog::NULL)
    assert_equal(0, fb.query('(always)').each.to_a.size)
    fb.insert
    assert_equal(1, fb.query('(always)').each.to_a.size)
  end

  def test_proper_logging
    log = Loog::Buffer.new
    fb = Factbase::Looged.new(Factbase.new, log)
    fb.insert
    fb.insert.bar = 3
    fb.insert
    fb.insert.str =
      "Он поскорей звонит. Вбегает
      К нему слуга француз Гильо,
      Халат и туфли предлагает
      И подает ему белье.
      Спешит Онегин одеваться,
      Слуге велит приготовляться
      С ним вместе ехать и с собой
      Взять также ящик боевой.
      Готовы санки беговые.
      Он сел, на мельницу летит.
      Примчались. Он слуге велит
      Лепажа стволы роковые
      Нести за ним, а лошадям
      Отъехать в поле к двум дубкам."
    fb.query('(exists bar)').each(&:to_s)
    fb.query('(not (exists bar))').delete!
    [
      'Inserted new fact #1',
      'Inserted new fact #2',
      'Set \'bar\' to 3 (Integer)',
      'Set \'str\' to "Он поскорей звонит. Вбегает\n   ... Отъехать в поле к двум дубкам." (String)',
      'Found 1 fact(s) by \'(exists bar)\'',
      'Deleted 3 fact(s) out of 4 by \'(not (exists bar))\''
    ].each do |s|
      assert(log.to_s.include?(s), "#{log}\n")
    end
  end
end
