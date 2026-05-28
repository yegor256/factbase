# frozen_string_literal: true

require_relative '../../../lib/factbase/syntax'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/sorted'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for sorted term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSorted < Factbase::Test
  def test_sorting
    list = Factbase::Syntax.new('(sorted x (always))').to_term.predict(
      [
        { 'x' => [8], 'y' => ['third'] }, { 'x' => [1], 'y' => ['first'] },
        { 'x' => [4], 'y' => ['second'] }
      ], Factbase.new, {}
    )
    assert(list.all?(Hash), "Why not all hashes in the list: #{list}")
    assert_equal('first second third', list.map { |m| m['y'].first }.join(' '))
  end

  def test_join_and_sort
    ff = Factbase.new(
      [
        { 'foo' => [888] }, { 'foo' => [111] },
        { 'foo' => [444] }
      ]
    ).query('(join "f<=foo" (head 1 (sorted foo (eq foo $foo))))').each.to_a
    assert_equal('888 111 444', ff.map { |m| m['f'].first }.join(' '))
  end
end
