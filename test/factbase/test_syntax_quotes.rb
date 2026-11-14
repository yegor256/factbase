# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/syntax'
require_relative '../../lib/factbase/term'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSyntaxQuotes < Factbase::Test
  def test_keeps_a_quote_of_the_other_kind_inside_a_literal
    fb = Factbase.new
    fb.insert.foo = "Jeff's"
    assert_equal(1, fb.query('(eq foo "Jeff\'s")').each.to_a.size)
  end

  def test_does_not_split_a_literal_with_two_intruding_quotes
    fb = Factbase.new
    fb.insert.foo = 'a" "b'
    assert_equal(1, fb.query(%q{(eq foo 'a" "b')}).each.to_a.size)
  end

  def test_finds_a_value_ending_in_backslashes_by_its_printed_query
    ['dir\\', 'dir\\\\'].each do |v|
      fb = Factbase.new
      fb.insert.path = v
      q = Factbase::Term.new(:eq, [:path, v]).to_s
      assert_equal(1, fb.query(q).each.to_a.size, "the value #{v.inspect} is not found by #{q}")
    end
  end

  def test_queries_escaped_quotes_after_odd_backslash_runs
    ["'", '"'].product(["'", '"'], (0..4).to_a).each do |delimiter, quote, count|
      value = "a#{'\\' * count}#{quote}b"
      query = "(eq path #{delimiter}a#{'\\' * ((count * 2) + 1)}#{quote}b#{delimiter})"
      fb = Factbase.new
      fb.insert.path = value
      fb.insert.path = "a#{'\\' * (count + 1)}#{quote}b"
      fb.insert.path = "a#{quote}b" unless count.zero?
      assert_equal(value, Factbase::Syntax.new(query).to_term.operands[1], query)
      assert_equal([value], fb.query(query).each.map(&:path), query)
    end
  end

  def test_queries_trailing_backslashes_after_even_runs
    ["'", '"'].product((1..4).to_a).each do |delimiter, count|
      value = "tail#{'\\' * count}"
      query = "(eq path #{delimiter}tail#{'\\' * (count * 2)}#{delimiter})"
      fb = Factbase.new
      fb.insert.path = value
      assert_equal(value, Factbase::Syntax.new(query).to_term.operands[1], query)
      assert_equal([value], fb.query(query).each.map(&:path), query)
    end
  end

  def test_preserves_even_runs_before_unescaped_other_quotes
    ["'", '"'].product([2, 4, 6, 8]).each do |delimiter, count|
      value = "a#{'\\' * count}#{delimiter == "'" ? '"' : "'"}b"
      query = "(eq path #{delimiter}#{value}#{delimiter})"
      fb = Factbase.new
      fb.insert.path = value
      assert_equal(value, Factbase::Syntax.new(query).to_term.operands[1], query)
      assert_equal([value], fb.query(query).each.map(&:path), query)
    end
  end

  def test_round_trips_backslashes_and_quotes_through_printed_queries
    values = ["'", '"'].product((0..4).to_a).map! { |quote, count| "a#{'\\' * count}#{quote}b" }
    values += (1..4).flat_map { |count| ["dir#{'\\' * count}", "a#{'\\' * count}b"] }
    values << "a\\'b\\\\\"c\\"
    values.each do |value|
      fb = Factbase.new
      fb.insert.path = value
      query = Factbase::Term.new(:eq, [:path, value]).to_s
      parsed = Factbase::Syntax.new(query).to_term
      assert_equal(value, parsed.operands[1], query)
      assert_equal(query, parsed.to_s)
      assert_equal([value], fb.query(query).each.map(&:path), query)
    end
  end
end
