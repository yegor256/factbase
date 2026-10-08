# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/pre'
require_relative '../test__helper'

class TestPreFailure < Factbase::Test
  def test_keeps_no_fact_whose_block_has_thrown
    fb = Factbase.new
    pre = Factbase::Pre.new(fb) { |_f| raise(StandardError, 'no') }
    assert_raises(StandardError, 'the block must be allowed to fail') { pre.insert }
    assert_equal(0, fb.size, 'a fact whose block has thrown cannot stay in the factbase')
  end

  def test_keeps_the_fact_when_the_block_succeeds
    fb = Factbase.new
    Factbase::Pre.new(fb) { |f| f.foo = 42 }.insert
    assert_equal(1, fb.size, 'a fact whose block succeeded must stay')
  end

  def test_keeps_no_fact_whose_block_has_thrown_inside_a_transaction
    fb = Factbase.new
    pre = Factbase::Pre.new(fb) { |_f| raise(StandardError, 'no') }
    assert_raises(StandardError, 'the block must be allowed to fail inside a transaction') do
      pre.txn(&:insert)
    end
    assert_equal(0, fb.size, 'a fact whose block has thrown cannot survive the transaction')
  end
end
