# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/churn'
require_relative '../../lib/factbase/tallied'

# Test of the churn that the caller passes to Tallied.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTalliedSharedChurn < Factbase::Test
  def test_rolls_back_the_churn_of_the_caller
    churn = Factbase::Churn.new
    fb = Factbase::Tallied.new(Factbase.new, churn)
    fb.txn do |t|
      t.insert.a = 1
      raise Factbase::Rollback
    end
    assert_predicate(churn, :zero?)
  end
end
