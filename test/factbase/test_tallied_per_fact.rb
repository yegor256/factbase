# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/tallied'

# Test of what Tallied counts as one change.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTalliedPerFact < Factbase::Test
  def test_counts_one_change_per_fact
    fb = Factbase::Tallied.new(Factbase.new)
    fb.insert
    fb.query('(always)').each do |f|
      f.x = 1
      f.y = 2
      f.z = 3
    end
    assert_equal(1, fb.churn.added)
  end
end
