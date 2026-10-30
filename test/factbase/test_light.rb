# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/light'

require_relative '../test__helper'

# Test.
class TestLight < Factbase::Test
  def test_explains_unsupported_factbase_operations
    fb = Factbase.new
    fb.txn do |light|
      assert_equal(
        "The 'export' operation is not available inside a transaction, use it on the factbase itself",
        assert_raises(StandardError) { light.export }.message
      )
    end
  end

  def test_keeps_unknown_operations_unknown
    assert_match(
      /undefined method [`']unknown'/,
      assert_raises(NoMethodError) { Factbase::Light.new(Factbase.new).unknown }.message
    )
  end

  def test_explains_nested_transaction_without_assuming_its_caller
    assert_equal(
      'A transaction cannot be started inside a transaction',
      assert_raises(StandardError) { Factbase::Light.new(Factbase.new).txn }.message
    )
  end

  def test_counts_facts_inserted_inside_a_transaction
    fb = Factbase.new
    fb.insert.foo = 1
    before = nil
    after = nil
    fb.txn do |t|
      before = t.size
      t.insert.bar = 2
      after = t.size
    end
    assert_equal(1, before)
    assert_equal(2, after)
  end

  def test_parses_a_term_inside_a_transaction
    fb = Factbase.new
    first = nil
    second = nil
    fb.txn do |t|
      first = t.to_term('(eq x 1)')
      second = t.to_term('(eq y 2)')
    end
    assert_equal('(eq x 1)', first.to_s)
    assert_equal('(eq y 2)', second.to_s)
  end

  def test_knows_factbase_operations_inside_a_transaction
    fb = Factbase.new
    known = nil
    unknown = nil
    fb.txn do |t|
      known = t.respond_to?(:export)
      unknown = t.respond_to?(:unknown)
    end
    assert(known)
    refute(unknown)
  end
end
