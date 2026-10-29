# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/many'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'many' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestMany < Factbase::Test
  def test_many
    t = Factbase::Many.new([:foo])
    refute(t.evaluate(fact('foo' => nil), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 1), [], Factbase.new))
    refute(t.evaluate(fact('foo' => '1234'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [1, 3, 5]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => []), [], Factbase.new))
  end

  def test_many_with_exactly_two_values
    t = Factbase::Many.new([:foo])
    assert(t.evaluate(fact('foo' => [1, 2]), [], Factbase.new))
    assert(t.evaluate(fact('foo' => %w[alpha beta]), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [42, 'hello']), [], Factbase.new))
  end

  def test_many_with_exactly_one_value
    t = Factbase::Many.new([:foo])
    refute(t.evaluate(fact('foo' => [42]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => ['solo']), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 99), [], Factbase.new))
  end

  def test_many_with_empty_property
    t = Factbase::Many.new([:foo])
    refute(t.evaluate(fact('foo' => []), [], Factbase.new))
    refute(t.evaluate(fact('foo' => nil), [], Factbase.new))
    refute(t.evaluate(fact('bar' => [1, 2]), [], Factbase.new))
  end

  def test_many_with_three_or_more_values
    t = Factbase::Many.new([:foo])
    assert(t.evaluate(fact('foo' => [1, 2, 3]), [], Factbase.new))
    assert(t.evaluate(fact('foo' => %w[a b c d]), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [10, 20, 30, 40, 50]), [], Factbase.new))
  end

  def test_query_with_exactly_two_values
    fb = Factbase.new
    f = fb.insert
    f.tag = 'ruby'
    f.tag = 'rails'
    assert_equal(1, fb.query('(many tag)').each.to_a.size)
    assert_empty(fb.query('(not (many tag))').each.to_a)
  end

  def test_query_with_one_value
    fb = Factbase.new
    fb.insert.tag = 'ruby'
    assert_empty(fb.query('(many tag)').each.to_a)
    assert_equal(1, fb.query('(not (many tag))').each.to_a.size)
  end

  def test_query_with_empty_property
    fb = Factbase.new
    fb.insert.other = 'value'
    assert_empty(fb.query('(many tag)').each.to_a)
    assert_equal(1, fb.query('(not (many tag))').each.to_a.size)
  end

  def test_query_with_three_or_more_values
    fb = Factbase.new
    f = fb.insert
    f.tag = 'a'
    f.tag = 'b'
    f.tag = 'c'
    assert_equal(1, fb.query('(many tag)').each.to_a.size)
    assert_empty(fb.query('(not (many tag))').each.to_a)
  end

  def test_query_filtering_across_multiple_facts
    fb = Factbase.new
    fb.insert.id = 0
    fb.insert.then do |f|
      f.id = 1
      f.tag = 'single'
    end
    fb.insert.then do |f|
      f.id = 2
      f.tag = 'alpha'
      f.tag = 'beta'
    end
    fb.insert.then do |f|
      f.id = 3
      f.tag = 'x'
      f.tag = 'y'
      f.tag = 'z'
    end
    assert_equal([2, 3], fb.query('(many tag)').each.map { |f| f['id'].first })
    assert_equal([0, 1], fb.query('(not (many tag))').each.map { |f| f['id'].first })
  end
end
