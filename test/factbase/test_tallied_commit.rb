# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/tallied'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTalliedCommit < Factbase::Test
  def test_counts_facts_of_a_thrown_commit
    fb = Factbase::Tallied.new(Factbase.new)
    fb.txn do |t|
      t.insert.foo = 1
      throw(:commit)
    end
    assert_equal(1, fb.size)
    assert_equal(1, fb.churn.inserted)
  end
end
