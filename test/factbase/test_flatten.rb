# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/flatten'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestFlatten < Minitest::Test
  def test_mapping
    maps = [{ 'b' => [42], 'i' => 1 }, { 'a' => 33, 'i' => 0 }, { 'c' => %w[hey you], 'i' => 2 }]
    to = Factbase::Flatten.new(maps, 'i').it
    assert_equal(33, to[0]['a'])
    assert_equal(42, to[1]['b'])
    assert_equal(2, to[2]['c'].size)
  end

  def test_without_sorter
    maps = [{ 'b' => [42], 'i' => [44] }, { 'a' => 33 }]
    to = Factbase::Flatten.new(maps, 'i').it
    assert_equal(33, to[0]['a'])
  end
end
