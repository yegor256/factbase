# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/syntax'

# Lists test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestLists < Factbase::Test
  def test_sorting
    maps = [
      { 'x' => [8], 'y' => ['third'] },
      { 'x' => [1], 'y' => ['first'] },
      { 'x' => [4], 'y' => ['second'] }
    ]
    t = Factbase::Syntax.new('(sorted x (always))').to_term
    list = t.predict(maps, Factbase.new, {})
    assert(list.all?(Hash), "Why not all hashes in the list: #{list}")
    assert_equal('first second third', list.map { |m| m['y'].first }.join(' '))
  end

  def test_inverting
    maps = [
      { 'x' => [33] },
      { 'x' => [54] },
      { 'x' => [12] }
    ]
    t = Factbase::Syntax.new('(inverted (always))').to_term
    list = t.predict(maps, Factbase.new, {})
    assert_equal('12 54 33', list.map { |m| m['x'].first }.join(' '))
  end
end
