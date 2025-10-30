# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/sorted'
require_relative '../../../lib/factbase/syntax'

# Test for sorted term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestSorted < Factbase::Test
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

  def test_join_and_sort
    maps = [
      { 'foo' => [888] },
      { 'foo' => [111] },
      { 'foo' => [444] }
    ]
    ff = Factbase.new(maps).query('(join "f<=foo" (head 1 (sorted foo (eq foo $foo))))').each.to_a
    assert_equal('888 111 444', ff.map { |m| m['f'].first }.join(' '))
  end
end
