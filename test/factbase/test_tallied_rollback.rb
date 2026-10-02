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
class TestTalliedRollback < Factbase::Test
  def test_forgets_facts_inserted_before_rollback
    fb = Factbase::Tallied.new(Factbase.new)
    fb.insert.foo = 1
    fb.txn do |t|
      t.insert.bar = 2
      throw(:rollback)
    end
    assert_equal(1, fb.size)
  end
end
