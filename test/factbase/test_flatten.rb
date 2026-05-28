# frozen_string_literal: true

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/flatten'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestFlatten < Factbase::Test
  def test_mapping
    to = Factbase::Flatten.new(
      [{ 'b' => [42], 'i' => 1 }, { 'a' => 33, 'i' => 0 }, { 'c' => %w[hey you], 'i' => 2 }],
      'i'
    ).it
    assert_equal(33, to[0]['a'])
    assert_equal(42, to[1]['b'])
    assert_equal(2, to[2]['c'].size)
  end

  def test_without_sorter
    assert_equal(33, Factbase::Flatten.new([{ 'b' => [42], 'i' => [44] }, { 'a' => 33 }], 'i').it[0]['a'])
  end
end
