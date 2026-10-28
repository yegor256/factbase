# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase/lazy_taped'
require_relative '../../lib/factbase/lazy_taped_array'
require_relative '../../lib/factbase/lazy_taped_hash'

require_relative '../test__helper'

# Test for Factbase::LazyTaped::LazyTapedHash.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Author:: Philip Belousov (belousovfilip@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestLazyTapedHash < Factbase::Test
  def test_keys
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    assert_read(hash, origin, %w[foo bar], hash.keys)
  end

  def test_map
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    assert_read(hash, origin, %w[bar=[2] foo=1], hash.map { |k, v| "#{k}=#{v}" }.sort!)
  end

  def test_reed_scalar
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    assert_kind_of(Integer, hash['foo'])
    assert_read(hash, origin, 1, hash['foo'])
  end

  def test_reed_array
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    assert_kind_of(Factbase::LazyTaped::LazyTapedArray, hash['bar'])
    assert_read(hash, origin, [2], hash['bar'].to_a)
  end

  def test_write_scalar
    hash, origin, added = wrap({ 'foo' => 1, 'bar' => [2] })
    hash['baz'] = 4
    assert_write(hash, origin, added, 4, hash['baz'])
  end

  def test_write_array
    hash, origin, added = wrap({ 'foo' => 1, 'bar' => [2] })
    hash['baz'] = [4]
    assert_write(hash, origin, added, 4, hash['baz'][0])
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

  def test_tracking_id
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    assert_equal(origin.object_id, hash.tracking_id)
    hash.ensure_copied_map
    refute_equal(origin.object_id, hash.tracking_id)
  end

  def test_copying_state
    hash, origin = wrap({ 'foo' => 1, 'bar' => [2] })
    refute_copied(hash, origin)
    hash.ensure_copied_map
    assert_copied(hash, origin)
  end

  def test_delegates_size
    hash, origin, = wrap({ 'a' => 1, 'b' => 2 })
    assert_read(hash, origin, 2, hash.size)
  end

  def test_method_missing_bang_triggers_copy
    hash, origin = wrap({ 'a' => 1, 'b' => nil, 'c' => 3 })
    hash.compact!
    assert_copied(hash, origin)
    assert_equal({ 'a' => 1, 'b' => nil, 'c' => 3 }, origin, 'Original should not be modified')
  end

  def test_non_bang_mutators_trigger_copy
    mutations = [
      [:delete, ['a'], nil, { 'b' => 2 }],
      [:store, ['c', 3], nil, { 'a' => 1, 'b' => 2, 'c' => 3 }],
      [:clear, [], nil, {}],
      [:update, [{ 'c' => 3 }], nil, { 'a' => 1, 'b' => 2, 'c' => 3 }],
      [:delete_if, [], 'a', { 'b' => 2 }],
      [:keep_if, [], 'b', { 'b' => 2 }]
    ]
    mutations.each do |method, arguments, key, expected|
      hash, origin, added = wrap({ 'a' => 1, 'b' => 2 })
      hash.public_send(method, *arguments) { |candidate, _value| candidate == key }
      assert_copied(hash, origin)
      assert_equal(expected, hash.to_h)
      assert_equal({ 'a' => 1, 'b' => 2 }, origin, 'Original should not be modified')
      refute_empty(added, 'Modified map should be tracked')
    end
  end

  def test_noop_mutators_are_not_journaled
    assert_noop { |hash| hash.delete('zzz') }
    assert_noop { |hash| hash.merge!({}) }
    assert_noop { |hash| hash.delete_if { false } }
    assert_noop(&:transform_values!)
  end

  def test_real_mutators_are_journaled
    assert_journaled { |hash| hash.delete('a') }
    assert_journaled { |hash| hash.store('b', 2) }
    assert_journaled { |hash| hash.merge!({ 'b' => 2 }) }
    assert_journaled(&:clear)
    assert_journaled { |hash| hash.delete_if { |key, _| key == 'a' } }
    assert_journaled { |hash| hash.transform_values! { |value| value + 1 } }
    assert_journaled(&:compare_by_identity)
  end

  def test_noop_after_compare_by_identity_is_not_journaled
    hash, _origin, added = wrap({ 'a' => 1 })
    hash.compare_by_identity
    refute_empty(added, 'compare_by_identity must be journaled')
    added.clear
    hash.merge!({})
    hash.delete('zzz')
    hash.delete_if { false }
    assert_empty(added, 'A no-op on an identity map must not be journaled')
  end

  def test_value_type_change_is_journaled
    hash, _origin, added = wrap({ 'a' => [1] })
    hash.transform_values! { |value| value.map { |item| Float(item) } }
    refute_empty(added, 'A change of a value type must be journaled')
    assert_equal([1.0], hash.to_h['a'])
  end

  def test_method_missing_reader_does_not_copy
    hash, origin = wrap({ 'a' => 1, 'b' => 2 })
    assert_read(hash, origin, 2, hash.size)
  end

  def test_reads_what_another_handle_wrote
    taped = Factbase::LazyTaped.new([{ 'id' => [1] }])
    handles = Array.new(2) { taped.each.first }
    handles.first['seen'] = [1]
    assert_equal([1], handles.last['seen'].to_a)
  end

  def test_does_not_expose_the_original_arrays
    %i[values map to_h].each do |name|
      fb = Factbase.new
      fb.insert.x = 1
      fb.txn do |transaction|
        read_array(transaction.each.first, name) << 2
        raise(Factbase::Rollback)
      end
      assert_equal({ 'x' => [1] }, fb.each.first.to_h, name)
    end
  end

  private

  def assert_noop
    hash, origin, added = wrap({ 'a' => 1 })
    yield(hash)
    assert_equal({ 'a' => 1 }, hash.to_h)
    assert_equal({ 'a' => 1 }, origin, 'Original should not be modified')
    assert_empty(added, 'No-op should not be tracked')
  end

  def assert_journaled
    hash, origin, added = wrap({ 'a' => 1 })
    yield(hash)
    refute_empty(added, 'Modified map should be tracked')
    assert_equal({ 'a' => 1 }, origin, 'Original should not be modified')
  end

  def read_array(hash, name)
    case name
    when :values then hash.values.first
    when :map then hash.map { |_key, items| items }.first
    else hash.to_h['x']
    end
  end

  def wrap(input)
    added = []
    origin = [{ 'foo' => 1 }, input, { 'baz' => [3] }]
    [Factbase::LazyTaped::LazyTapedHash.new(origin[1], Factbase::LazyTaped.new(origin), added), origin[1], added]
  end

  def assert_copied(hash, origin)
    refute_equal(origin.object_id, hash.tracking_id)
    assert_predicate(hash, :copied?)
  end

  def refute_copied(hash, origin)
    assert_equal(origin.object_id, hash.tracking_id)
    refute_predicate(hash, :copied?)
  end

  def assert_read(hash, origin, expected, actual)
    assert_equal(expected, actual)
    refute_copied(hash, origin)
  end

  def assert_write(hash, origin, added, expected, actual)
    assert_equal(expected, actual)
    refute_empty(added)
    assert_copied(hash, origin)
  end
end
