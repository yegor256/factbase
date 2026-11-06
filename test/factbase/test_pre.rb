# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require_relative '../../lib/factbase/pre'

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

  def test_runs_block_on_imported_facts
    src = Factbase.new
    src.insert.foo = 1
    fb = Factbase::Pre.new(Factbase.new) { |f| f._id = 42 }
    fb.import(src.export)
    f = fb.query('(always)').each.to_a.first
    assert_equal(42, f._id, 'The block must run on an imported fact')
    assert_equal(1, f.foo)
  end

  def test_passes_self_as_second_argument_on_insert
    seen = nil
    fb =
      Factbase::Pre.new(Factbase.new) do |_fact, fbt|
        seen = fbt
      end
    fb.insert
    assert_instance_of(Factbase::Pre, seen)
    assert_same(fb, seen)
  end

  def test_passes_pre_as_second_argument_in_transaction
    seen = []
    fb =
      Factbase::Pre.new(Factbase.new) do |_fact, fbt|
        seen << fbt
      end
    tx = nil
    fb.txn do |txn|
      tx = txn
      txn.insert
      txn.insert
    end
    assert_equal(2, seen.size)
    seen.each do |fbt|
      assert_instance_of(Factbase::Pre, fbt)
      assert_same(tx, fbt)
    end
  end

  def test_recursive_insert_through_block_argument
    runs = 0
    fb =
      Factbase::Pre.new(Factbase.new) do |fact, fbt|
        runs += 1
        if runs == 1
          fact.role = 'parent'
          fbt.insert.role = 'child'
        end
        fact.tagged = true
      end
    fb.insert
    assert_equal(2, runs)
    assert_equal(2, fb.size)
    assert_equal(2, fb.query('(eq tagged true)').each.to_a.size)
  end

  def test_recursive_insert_inside_transaction
    runs = 0
    fb =
      Factbase::Pre.new(Factbase.new) do |fact, fbt|
        runs += 1
        if runs == 1
          fact.role = 'first'
          fbt.insert
        end
        fact.done = true
      end
    fb.txn(&:insert)
    assert_equal(2, runs)
    assert_equal(2, fb.size)
    assert_equal(2, fb.query('(eq done true)').each.to_a.size)
  end

  def test_passes_self_as_second_argument_on_import
    seen = nil
    fb =
      Factbase::Pre.new(Factbase.new) do |_fact, fbt|
        seen = fbt
      end
    src = Factbase.new
    src.insert.foo = 1
    fb.import(src.export)
    assert_instance_of(Factbase::Pre, seen)
    assert_same(fb, seen)
  end
end
