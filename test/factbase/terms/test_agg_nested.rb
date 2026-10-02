# frozen_string_literal: true

require_relative '../../../lib/factbase'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test of a term nested inside 'agg'.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestAggNested < Factbase::Test
  def test_agg_inside_agg
    assert_equal(1, matched('(gt foo (agg (always) (agg (always) (count))))'))
  end

  def test_term_that_reads_the_outer_fact
    assert_equal(0, matched('(gt foo (agg (always) (plus foo 1)))'))
  end

  private

  def matched(query)
    fb = Factbase.new
    fb.insert.foo = 3
    fb.query(query).each.to_a.size
  end
end
