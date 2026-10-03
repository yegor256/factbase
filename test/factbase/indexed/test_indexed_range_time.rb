# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'time'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedRangeTime < Factbase::Test
  def test_keeps_a_fact_inside_the_same_second
    moment = Time.parse('2024-01-01T00:00:01.9Z')
    target = Time.parse('2024-01-01T00:00:01.99Z')
    %w[gt gte lt lte].each do |op|
      origin = Factbase.new
      origin.insert.when = moment
      indexed = Factbase::IndexedFactbase.new(Factbase.new)
      indexed.insert.when = moment
      query = "(#{op} when $t)"
      assert_equal(
        origin.query(query).each(origin, { 't' => [target] }).to_a.size,
        indexed.query(query).each(indexed, { 't' => [target] }).to_a.size,
        query
      )
    end
  end
end
