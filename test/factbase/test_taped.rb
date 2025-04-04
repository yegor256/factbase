# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/taped'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestTaped < Factbase::Test
  def test_tracks_insertion
    t = Factbase::Taped.new([])
    t << {}
    assert_equal(1, t.inserted.size)
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
    h = { f: 5 }
    t = Factbase::Taped.new([h])
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
end
