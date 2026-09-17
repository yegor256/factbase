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
class TestIndexedEqTime < Factbase::Test
  def test_finds_facts_by_time
    when_ = Time.parse('2024-03-01T00:00:00Z')
    origin = Factbase.new
    origin.insert.when = when_
    origin.insert.when = when_
    origin.insert.when = Time.parse('2025-01-01T00:00:00Z')
    query = "(eq when #{when_.utc.iso8601})"
    assert_equal(origin.query(query).each.to_a.size, Factbase::IndexedFactbase.new(origin).query(query).each.to_a.size)
  end
end
