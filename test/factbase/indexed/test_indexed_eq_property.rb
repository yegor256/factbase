# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedEqProperty < Factbase::Test
  def test_compares_two_properties
    origin = Factbase.new
    first = origin.insert
    first.k = 'x'
    first.a = 1
    first.b = 1
    second = origin.insert
    second.k = 'y'
    second.a = 2
    second.b = 2
    fb = Factbase::IndexedFactbase.new(origin)
    ['(eq a b)', '(and (eq k "x") (eq a b))'].each do |q|
      assert_equal(origin.query(q).each.to_a.size, fb.query(q).each.to_a.size, q)
    end
  end
end
