# frozen_string_literal: true

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/rules'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestRulesAgg < Factbase::Test
  def test_sees_the_facts_of_the_factbase
    origin = Factbase.new
    origin.insert.foo = 1
    origin.insert.foo = 2
    fb = Factbase::Rules.new(origin, '(gt (agg (always) (count)) 0)')
    fb.query('(exists foo)').each { |f| f.bar = 9 }
    assert_equal(2, origin.query('(exists bar)').each.to_a.size)
  end
end
