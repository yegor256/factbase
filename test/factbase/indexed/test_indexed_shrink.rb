# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Test of the indexes over a scoped array that gets shorter.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedShrink < Factbase::Test
  def test_answers_like_the_plain_factbase_after_the_scope_shrinks
    ['(eq k 1)', '(exists k)', '(absent e)', '(one k)', '(not (eq s 0))', '(and (eq k 1) (eq s 3))'].each do |q|
      plain = Factbase.new
      fb = Factbase::IndexedFactbase.new(Factbase.new)
      [plain, fb].each do |b|
        4.times do |i|
          f = b.insert
          f.s = i
          f.k = 1
        end
      end
      mine = []
      fb.each { |m| mine << m }
      theirs = []
      plain.each { |m| theirs << m }
      fb.query(q, mine).each.to_a
      mine.pop(2)
      theirs.pop(2)
      assert_equal(
        plain.query(q, theirs).each.map { |f| f['s'] },
        fb.query(q, mine).each.map { |f| f['s'] },
        "#{q} answered with facts that are no longer in the scope"
      )
    end
  end
end
