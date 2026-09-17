# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestAccumReadAfterWrite < Factbase::Test
  def test_reads_what_the_fact_reads
    fb = Factbase.new
    fb.insert.bar = 1
    fb.query('(exists bar)').each do |f|
      f.bar = 5
      assert_equal(1, f.bar)
      assert_equal([1, 5], f['bar'])
    end
    assert_equal(1, fb.query('(exists bar)').each.to_a.first.bar)
  end
end
