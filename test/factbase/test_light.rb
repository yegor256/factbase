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
      /undefined method 'unknown'/,
      assert_raises(NoMethodError) { Factbase::Light.new(Factbase.new).unknown }.message
    )
  end

  def test_explains_nested_transaction_without_assuming_its_caller
    assert_equal(
      'A transaction cannot be started inside a transaction',
      assert_raises(StandardError) { Factbase::Light.new(Factbase.new).txn }.message
    )
  end
end
