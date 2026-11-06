# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require_relative '../../lib/factbase/pre'
require_relative '../../lib/factbase/rules'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestPre < Factbase::Test
  def test_validates_initialized_imports_with_rules
    fb =
      Factbase::Pre.new(Factbase::Rules.new(Factbase.new, '(and (exists seq) (exists payload))')) do |fact, context|
        fact.seq = (context.query('(max seq)').one || 0) + 1
      end
    source = Factbase.new
    %w[first second].each { |payload| source.insert.payload = payload }
    fb.import(source.export)
    assert_equal([1, 2], fb.query('(always)').map(&:seq))
  end

  def test_import_initializer_sees_previous_imported_facts
    fb =
      Factbase::Pre.new(Factbase.new) do |fact, context|
        fact.seq = (context.query('(max seq)').one || 0) + 1
        fact.total = context.size
      end
    fb.insert.payload = 'existing'
    source = Factbase.new
    %w[first second].each { |payload| source.insert.payload = payload }
    fb.import(source.export)
    assert_equal([1, 2, 3], fb.query('(always)').map(&:seq))
    assert_equal([1, 2, 3], fb.query('(always)').map(&:total))
    assert_equal(%w[existing first second], fb.query('(always)').map(&:payload))
  end

  def test_rolls_back_the_import_when_an_initializer_fails
    fb =
      Factbase::Pre.new(Factbase.new) do |fact|
        raise(RuntimeError, 'initializer failed') if fact['payload'] == ['second']
        fact.initialized = 1
      end
    fb.insert.payload = 'existing'
    source = Factbase.new
    %w[first second].each { |payload| source.insert.payload = payload }
    assert_raises(RuntimeError) { fb.import(source.export) }
    assert_equal(['existing'], fb.query('(always)').map(&:payload))
    assert_equal([1], fb.query('(always)').map(&:initialized))
  end

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
end
