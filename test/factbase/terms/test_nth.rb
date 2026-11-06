# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/nth'

require_relative '../../test__helper'

# Test for unique term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestNth < Factbase::Test
  def test_nth
    assert_equal(
      %w[2 3],
      Factbase::Nth.new([1, :number]).evaluate(
        fact,
        [{ 'number' => '1' }, { 'number' => %w[2 3] }, { 'number' => '4' }], Factbase.new
      )
    )
  end

  def test_reads_facts_inside_txn
    fb = Factbase.new
    fb.insert.id = 1
    fb.txn do |fbt|
      fbt.insert.id = 2
      assert_equal([[1], [2]], ['(eq id (first id))', '(eq id (nth 1 id))'].map { |q| fbt.query(q).each.map(&:id) })
    end
  end

  def test_refuses_a_negative_position
    t = Factbase::Nth.new([-1, :letter])
    e =
      assert_raises(ArgumentError) do
        t.evaluate(fact, [{ 'letter' => 'a' }, { 'letter' => 'b' }], Factbase.new)
      end
    assert_includes(e.message, 'A non-negative position is expected, but -1 provided', e.message)
  end

  def test_reads_the_position_from_a_param
    fb = Factbase.new
    [5, 7, 9].each { |i| fb.insert.v = i }
    assert_equal([7], fb.query('(eq v (nth $n v))').each(fb, 'n' => [1]).map(&:v))
  end

  def test_reads_the_position_from_a_sub_term
    fb = Factbase.new
    [5, 7, 9].each { |i| fb.insert.v = i }
    assert_equal([7], fb.query('(agg (always) (nth (minus 2 1) v))').one)
  end

  def test_refuses_a_position_that_is_not_an_integer
    e = assert_raises(ArgumentError) { Factbase::Nth.new(['1', :letter]).evaluate(fact, [{ 'letter' => 'a' }], Factbase.new) }
    assert_includes(e.message, 'An integer is expected, but 1 provided', e.message)
  end

  def test_nth_out_of_bounds
    assert_nil(
      Factbase::Nth.new([5, :letter]).evaluate(
        fact,
        [{ 'letter' => 'a' }, { 'letter' => 'b' }, { 'letter' => 'c' }], Factbase.new
      )
    )
  end

  def test_gives_nil_for_a_huge_position
    assert_nil(
      Factbase::Nth.new([99_999_999_999_999_999_999, :letter]).evaluate(nil, [{ 'letter' => 'a' }], Factbase.new)
    )
  end

  def test_modifying_returned_array_does_not_alter_fact_via_append
    fb = Factbase.new
    f = fb.insert
    f.x = 10
    f.x = 20
    fb.query('(nth 0 x)').one << 99
    assert_equal([10, 20], f['x'])
    assert_equal(10, f.x)
  end

  def test_modifying_returned_array_does_not_alter_fact_via_index_assignment
    fb = Factbase.new
    f = fb.insert
    f.x = 10
    f.x = 20
    fb.query('(nth 0 x)').one[0] = 99
    assert_equal([10, 20], f['x'])
    assert_equal(10, f.x)
  end

  def test_modifying_returned_array_at_nonzero_position_does_not_alter_fact
    fb = Factbase.new
    fb.insert.x = 1
    f = fb.insert
    f.x = 10
    f.x = 20
    v = fb.query('(nth 1 x)').one
    v << 99
    v[0] = 99
    assert_equal([10, 20], f['x'])
    assert_equal(10, f.x)
  end

  def test_evaluating_nth_returns_duplicate_of_array
    map = { 'num' => [1, 2, 3] }
    v = Factbase::Nth.new([0, :num]).evaluate(fact, [map], Factbase.new)
    v << 99
    v[0] = 42
    assert_equal([1, 2, 3], map['num'])
  end
end
