# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedRangeParams < Factbase::Test
  def test_answers_the_way_a_plain_factbase_answers
    {
      '(gt x $t)' => [10, 1],
      '(gte x $t)' => [10, 1],
      '(lt x $t)' => [0, 4],
      '(lte x $t)' => [0, 4]
    }.each do |query, values|
      origin = Factbase.new
      5.times { |i| origin.insert.x = i }
      indexed = Factbase::IndexedFactbase.new(Factbase.new)
      5.times { |i| indexed.insert.x = i }
      assert_equal(
        origin.query(query).each(origin, { 't' => values }).to_a.map(&:x),
        indexed.query(query).each(indexed, { 't' => values }).to_a.map(&:x),
        query
      )
    end
  end
end
