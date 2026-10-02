# frozen_string_literal: true

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/taped'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTaped < Factbase::Test
  def test_tracks_insertion
    t = Factbase::Taped.new([])
    t << {}
    assert_equal(1, t.inserted.size)
  end

  def test_checks_for_emptiness
    refute_empty(Factbase::Taped.new([{ foo: 'yes' }]))
  end

  def test_joins_with_non_empty
    t = Factbase::Taped.new([{ foo: 'yes' }])
    t &= [{ bar: 'no' }]
    assert_equal(0, t.size)
  end

  def test_joins_with_empty
    t = Factbase::Taped.new([{ foo: 'yes' }])
    t &= []
    assert_equal(0, t.size)
  end

  def test_disjoins_with_empty
    t = Factbase::Taped.new([{ bar: 'oops' }])
    t |= []
    assert_equal(1, t.size)
  end

  def test_disjoins_with_non_empty
    t = Factbase::Taped.new([{ bar: 'oops' }])
    t |= [{ bar: 'no' }]
    assert_equal(2, t.size)
  end

  def test_tracks_deletion
    t = Factbase::Taped.new([{ x: 1 }, { x: 2 }])
    t.delete_if { |m| m[:x] == 1 }
    assert_equal(1, t.deleted.size)
  end

  def test_tracks_addition
    h = { f: 5 }
    t = Factbase::Taped.new([h])
    t.each do |m|
      m[:bar] = 66
    end
    assert_equal(1, t.added.size)
    assert_equal(h.object_id, t.added.first)
  end

  def test_tracks_addition_uniquely
    t = Factbase::Taped.new([{ f: 5 }])
    t.each do |m|
      m[:bar] = 66
      m[:foo] = 77
    end
    assert_equal(1, t.added.size)
  end

  def test_tracks_factbase
    t = Factbase::Taped.new([])
    fb = Factbase.new(t)
    fb.insert
    fb.query('(always)').each do |f|
      f.foo = 42
      f.foo = 5
    end
    fb.query('(always)').delete!
    assert_equal(1, t.inserted.size)
    assert_equal(1, t.added.size)
    assert_equal(1, t.deleted.size)
  end

  def test_dont_track_failed_append
    seed = Random.new_seed
    item = "ключ-#{Random.new(seed).rand(1_000)}"
    t = Factbase::Taped.new([{ foo: ['', '❤'].freeze }])
    t.each do |m|
      m[:foo] << item
    rescue FrozenError
      nil
    end
    assert_empty(t.added, "churn is not empty after an append that failed, seed #{seed}")
  end

  def test_dont_track_failed_uniq
    seed = Random.new_seed
    t = Factbase::Taped.new([{ foo: ["däß-#{Random.new(seed).rand(1_000)}", ''].freeze }])
    t.each do |m|
      m[:foo].uniq!
    rescue FrozenError
      nil
    end
    assert_empty(t.added, "churn is not empty after a uniq that failed, seed #{seed}")
  end

  def test_tracks_array_append
    h = { foo: %w[ü] }
    t = Factbase::Taped.new([h])
    t.each { |m| m[:foo] << 'ø' }
    assert_equal([h.object_id], t.added, 'churn does not hold the fact whose array got an item')
  end

  def test_tracks_array_uniq
    h = { foo: %w[я я] }
    t = Factbase::Taped.new([h])
    t.each { |m| m[:foo].uniq! }
    assert_equal([h.object_id], t.added, 'churn does not hold the fact whose array lost a duplicate')
  end

  def test_returns_array_after_append
    t = Factbase::Taped.new([{ foo: %w[ǝ] }])
    result = nil
    t.each { |m| result = m[:foo] << 'ß' }
    assert_equal(%w[ǝ ß], result, 'appending an item does not return the array it went into')
  end

  def test_dont_return_array_after_useless_uniq
    t = Factbase::Taped.new([{ foo: %w[ä ö] }])
    result = false
    t.each { |m| result = m[:foo].uniq! }
    assert_nil(result, 'uniq of an array without duplicates does not return nil')
  end
end
