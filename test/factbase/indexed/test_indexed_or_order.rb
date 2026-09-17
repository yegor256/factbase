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
class TestIndexedOrOrder < Factbase::Test
  def test_yields_in_insertion_order
    origin = Factbase.new
    first = origin.insert
    first.label = 'first'
    first.a = 1
    second = origin.insert
    second.label = 'second'
    second.b = 2
    100.times { origin.insert.c = 3 }
    query = '(or (eq b 2) (eq a 1))'
    assert_equal(origin.query(query).each.to_a.map(&:label), Factbase::IndexedFactbase.new(origin).query(query).each.to_a.map(&:label))
  end
end
