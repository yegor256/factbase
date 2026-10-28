# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

# Returning a literal must not let a caller rewrite the parsed query.
class TestQueryLiterals < Factbase::Test
  def test_derived_strings_cannot_change_other_rows_or_later_evaluations
    base = Factbase.new
    2.times { |number| base.insert.number = number }
    query = base.query("(as label 'original')")
    rows = query.each.to_a
    assert_raises(FrozenError) { rows.first.label.replace('changed') }
    assert_raises(FrozenError) { rows.first['label'].first.replace('changed') }
    assert_equal(%w[original original], rows.map(&:label))
    assert_equal(%w[original original], query.each.map(&:label))
    assert_equal([nil, nil], base.each.map { |map| map['label'] })
  end

  def test_scalar_strings_cannot_change_later_evaluations
    query = Factbase.new.query("(at 0 'original')")
    assert_raises(FrozenError) { query.one.replace('changed') }
    assert_equal('original', query.one)
  end

  def test_nested_literals_cannot_change_later_evaluations
    query = Factbase.new.query("(at 0 (at 0 'original'))")
    assert_raises(FrozenError) { query.one.replace('changed') }
    assert_equal('original', query.one)
  end
end
