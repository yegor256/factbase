# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/query'
require_relative '../../lib/factbase/impatient'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestImpatient < Factbase::Test
  class SlowFactbase < Factbase
    class SlowQuery < Factbase::Query
      def one(fb = @fb, params = {})
        sleep 0.2
        super
      end
    end

    def query(term, maps = nil)
      maps ||= @maps
      term = to_term(term) if term.is_a?(String)
      SlowQuery.new(maps, term, self)
    end
  end

  class SlowDeleteFactbase < Factbase
    class SlowQuery < Factbase::Query
      def delete!(fb = @fb)
        sleep 0.2
        super
      end
    end

    def query(term, maps = nil)
      maps ||= @maps
      term = to_term(term) if term.is_a?(String)
      SlowQuery.new(maps, term, self)
    end
  end

  class SlowEnoughFactbase < Factbase
    class SlowQuery < Factbase::Query
      def one(fb = @fb, params = {})
        sleep 1.5
        super
      end
    end

    def query(term, maps = nil)
      maps ||= @maps
      term = to_term(term) if term.is_a?(String)
      SlowQuery.new(maps, term, self)
    end
  end

  def test_simple_query
    fb = Factbase::Impatient.new(Factbase.new)
    fb.insert
    fb.insert.bar = 3
    found = 0
    fb.query('(exists bar)').each do |f|
      assert_predicate(f.bar, :positive?)
      f.foo = 42
      assert_equal(42, f.foo)
      found += 1
    end
    assert_equal(1, found)
    assert_equal(2, fb.size)
  end

  def test_query_one
    fb = Factbase::Impatient.new(Factbase.new)
    fb.insert
    fb.insert.bar = 42
    assert_equal(1, fb.query('(agg (exists bar) (count))').one)
    assert_equal([42], fb.query('(agg (exists bar) (first bar))').one)
  end

  def test_query_timeout
    fb = Factbase::Impatient.new(Factbase.new, timeout: 0.1)
    1000.times do
      fb.insert.value = rand(1000)
    end
    ex =
      assert_raises(StandardError) do
        fb.query('(always)').each do
          sleep 0.2
        end
      end
    assert_includes(ex.message, 'timed out after')
  end

  def test_query_one_timeout
    slow = SlowFactbase.new
    10_000.times do
      slow.insert.value = rand(1000)
    end
    fb = Factbase::Impatient.new(slow, timeout: 0.01)
    ex =
      assert_raises(StandardError) do
        fb.query('(agg (min value))').one
      end
    assert_includes(ex.message, 'timed out after')
  end

  def test_delete_timeout
    slow = SlowDeleteFactbase.new
    1000.times do |i|
      slow.insert.value = i
    end
    fb = Factbase::Impatient.new(slow, timeout: 0.01)
    ex =
      assert_raises(StandardError) do
        fb.query('(gt value 500)').delete!
      end
    assert_includes(ex.message, 'timed out after')
  end

  def test_with_txn
    fb = Factbase::Impatient.new(Factbase.new)
    assert(
      fb.txn do |fbt|
        fbt.insert.foo = 42
      end
    )
    assert_equal(1, fb.size)
  end

  def test_with_txn_timeout
    fb = Factbase::Impatient.new(Factbase.new, timeout: 1)
    fb.txn do |fbt|
      fbt.insert.slow = 42
      ex =
        assert_raises(StandardError) do
          fbt.query('(always)').each do
            sleep 1.1
          end
        end
      assert_includes(ex.message, 'timed out after')
    end
  end

  def test_returns_int
    fb = Factbase.new
    fb.insert
    fb.insert
    assert_equal(2, Factbase::Impatient.new(fb).query('(always)').each(&:to_s))
  end

  def test_returns_int_when_empty
    fb = Factbase.new
    assert_equal(0, Factbase::Impatient.new(fb).query('(always)').each(&:to_s))
  end

  def test_returns_to_s_correctly
    fb = Factbase.new
    q = '(always)'
    assert_equal(q, fb.query(q).to_s)
  end

  def test_enumerator_support
    fb = Factbase::Impatient.new(Factbase.new)
    assert_equal(0, fb.query('(always)').each.to_a.size)
    fb.insert
    assert_equal(1, fb.query('(always)').each.to_a.size)
  end

  def test_query_completes_before_timeout
    fb = Factbase::Impatient.new(Factbase.new, timeout: 1)
    100.times do |i|
      fb.insert.index = i
    end
    count = 0
    fb.query('(always)').each do |f|
      count += 1
      assert_equal(count - 1, f.index)
    end
    assert_equal(100, count)
  end

  def test_custom_timeout
    slow = SlowEnoughFactbase.new
    slow.insert.value = 42
    fb = Factbase::Impatient.new(slow, timeout: 2)
    start = Time.now
    result = fb.query('(agg (eq value 42) (first value))').one
    elapsed = Time.now - start
    assert_operator(elapsed, :>=, 1.5)
    assert_equal([42], result)
  end

  def test_nil_factbase_raises
    ex =
      assert_raises(StandardError) do
        Factbase::Impatient.new(nil)
      end
    assert_equal('The "fb" is nil', ex.message)
  end
end
