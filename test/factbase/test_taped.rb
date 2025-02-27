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
end
