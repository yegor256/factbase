# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedEqNumbers < Factbase::Test
  def test_matches_across_numeric_types
    origin = Factbase.new
    origin.insert.a = 1
    origin.insert.a = 2.0
    fb = Factbase::IndexedFactbase.new(origin)
    ['(eq a 1.0)', '(eq a 2)', '(eq a 1)', '(eq a 2.0)'].each do |q|
      assert_equal(origin.query(q).each.to_a.size, fb.query(q).each.to_a.size, q)
    end
  end
end
