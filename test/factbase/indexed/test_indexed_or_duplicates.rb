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
class TestIndexedOrDuplicates < Factbase::Test
  def test_keeps_two_facts_of_equal_content
    origin = Factbase.new
    origin.insert.a = 1
    origin.insert.a = 1
    fb = Factbase::IndexedFactbase.new(origin)
    query = '(or (eq a 1) (eq a 99))'
    assert_equal(origin.query(query).each.to_a.size, fb.query(query).each.to_a.size)
  end
end
