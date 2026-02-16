# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase/lazy_taped'
require_relative '../../lib/factbase/lazy_taped_hash'
require_relative '../../lib/factbase/lazy_taped_array'

# Test for Factbase::LazyTaped::LazyTapedHash.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Author:: Philip Belousov (belousovfilip@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestLazyTapedHash < Factbase::Test
  def test_keys
    hash, = wrap({ 'foo' => 1, 'bar' => [2] })
    assert_equal(%w[foo bar], hash.keys)
  end

  def test_map
    hash, = wrap({ 'foo' => 1, 'bar' => [2] })
    assert_equal(%w[bar=[2] foo=1], hash.map { |k, v| "#{k}=#{v}" }.sort)
  end

  def test_reed_scalar
    hash, = wrap({ 'foo' => 1, 'bar' => [2] })
    assert_kind_of(Integer, hash['foo'])
    assert_equal(1, hash['foo'])
  end

  def test_reed_array
    hash, = wrap({ 'foo' => 1, 'bar' => [2] })
    assert_kind_of(Factbase::LazyTaped::LazyTapedArray, hash['bar'])
    assert_equal([2], hash['bar'].to_a)
  end

  def test_write_scalar
    hash, _, added = wrap({ 'foo' => 1, 'bar' => [2] })
    hash['baz'] = 4
    assert_equal(4, hash['baz'])
    refute_empty(added)
  end

  def test_write_array
    hash, _, added = wrap({ 'foo' => 1, 'bar' => [2] })
    hash['baz'] = [4]
    assert_equal(4, hash['baz'][0])
    refute_empty(added)
  end

  def test_ensure_copied_after_insertion
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    hash['foo'] = [2]
    assert_copied(hash, origin)
  end

  def test_ensure_copied_after_ensure_copied_map
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    hash.ensure_copied_map
    assert_copied(hash, origin)
  end

  def test_ensure_copied_after_get_copied_array
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    hash.get_copied_array('foo')
    assert_copied(hash, origin)
  end

  def test_not_ensure_copied_after_reed
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    hash['foo']
    refute_copied(hash, origin)
  end

  def test_not_ensure_copied_after_keys
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    hash.keys
    refute_copied(hash, origin)
  end

  def test_tracking_id
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    assert_equal(origin.object_id, hash.tracking_id)
    hash.ensure_copied_map
    refute_equal(origin.object_id, hash.tracking_id)
  end

  def test_not_ensure_copied_after_map
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    hash.map { |k, v| "#{k}=#{v}" }
    refute_copied(hash, origin)
  end

  def test_copying_state
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    refute_copied(hash, origin)
    hash.ensure_copied_map
    assert_copied(hash, origin)
  end

  def test_delegates_size
    hash, = wrap({ 'a' => 1, 'b' => 2 })
    assert_equal(2, hash.size)
  end

  private

  def wrap(input)
    added = []
    origin = [{ 'foo' => 1 }, input, { 'baz' => [3] }]
    lt = Factbase::LazyTaped.new(origin)
    [Factbase::LazyTaped::LazyTapedHash.new(origin[1], lt, added), origin[1], added]
  end

  def assert_copied(hash, origin)
    refute_equal(origin.object_id, hash.tracking_id)
    assert_predicate(hash, :copied?)
  end

  def refute_copied(hash, origin)
    assert_equal(origin.object_id, hash.tracking_id)
    refute_predicate(hash, :copied?)
  end
end
