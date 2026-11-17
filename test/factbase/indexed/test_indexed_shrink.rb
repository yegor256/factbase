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
      assert_answers_like_the_plain_factbase(q)
    end
  end

  def test_answers_like_the_plain_factbase_after_the_scope_shrinks_with_gt
    assert_answers_like_the_plain_factbase('(gt s 1)', (0..5).to_a)
  end

  def test_answers_like_the_plain_factbase_after_the_scope_shrinks_with_gte
    assert_answers_like_the_plain_factbase('(gte s 2)', (0..5).to_a)
  end

  def test_answers_like_the_plain_factbase_after_the_scope_shrinks_with_lt
    assert_answers_like_the_plain_factbase('(lt s 5)', (0..5).to_a)
  end

  def test_answers_like_the_plain_factbase_after_the_scope_shrinks_with_lte
    assert_answers_like_the_plain_factbase('(lte s 4)', (0..5).to_a)
  end

  private

  def assert_answers_like_the_plain_factbase(query, values = (0..3).to_a)
    plain = Factbase.new
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    [plain, fb].each do |b|
      values.each do |v|
        f = b.insert
        f.s = v
        f.k = 1
      end
    end
    mine = fb.to_enum(:each).to_a
    theirs = plain.to_enum(:each).to_a
    fb.query(query, mine).each.to_a
    mine.pop(2)
    theirs.pop(2)
    assert_equal(
      plain.query(query, theirs).each.map { |f| f['s'] },
      fb.query(query, mine).each.map { |f| f['s'] },
      "#{query} answered with facts that are no longer in the scope"
    )
  end
end
