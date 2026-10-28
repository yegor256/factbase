# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require_relative '../../lib/factbase/pre'
require_relative '../../lib/factbase/term'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestPre < Factbase::Test
  def test_simple_setting
    fb = Factbase::Pre.new(Factbase.new) { |f| f.foo = 42 }
    f = fb.insert
    assert_equal(42, f.foo)
    assert_equal(1, fb.query('(always)').each.to_a.size)
  end

  def test_in_transaction
    fb =
      Factbase::Pre.new(Factbase.new) do |f, fbt|
        f.total = fbt.size
      end
    fb.txn do |fbt|
      fbt.insert
      fbt.insert
    end
    arr = fb.query('(always)').each.to_a
    assert_equal(1, arr[0].total)
    assert_equal(2, arr[1].total)
  end

  def test_runs_block_on_a_fact_inserted_by_a_term_with_default_context
    n = :_pre_insert_default
    Factbase::Term.new(:defn, [n, 'fb.insert.value = 2; fb.size']).evaluate(nil, [], Factbase.new)
    begin
      fb = Factbase::Pre.new(Factbase.new) { |f| f.stamp = 1 }
      assert_equal(1, fb.query("(#{n})").one)
      assert_equal([1], fb.query('(always)').each.to_a.first['stamp'], 'the block must run on the inserted fact')
    ensure
      Factbase::Term.new(:undef, [n]).evaluate(nil, [], Factbase.new)
    end
  end

  def test_runs_block_on_a_fact_inserted_by_a_term_in_each_with_default_context
    n = :_pre_insert_each
    Factbase::Term.new(:defn, [n, 'fb.insert.value = 3 if fb.size == 1; true']).evaluate(nil, [], Factbase.new)
    begin
      fb = Factbase::Pre.new(Factbase.new) { |f| f.stamp = 1 }
      fb.insert.seed = 1
      fb.query("(#{n})").each.to_a
      assert_equal(2, fb.size)
      assert_equal(2, fb.query('(exists stamp)').each.to_a.size, 'every fact must carry the stamp')
    ensure
      Factbase::Term.new(:undef, [n]).evaluate(nil, [], Factbase.new)
    end
  end

  def test_runs_block_on_imported_facts
    src = Factbase.new
    src.insert.foo = 1
    fb = Factbase::Pre.new(Factbase.new) { |f| f._id = 42 }
    fb.import(src.export)
    f = fb.query('(always)').each.to_a.first
    assert_equal(42, f._id, 'The block must run on an imported fact')
    assert_equal(1, f.foo)
  end
end
