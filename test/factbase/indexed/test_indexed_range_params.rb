# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Indexed range terms with parameters that hold several values.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedRangeParams < Factbase::Test
  def test_agrees_with_the_plain_factbase_on_many_values
    plain = Factbase.new
    indexed = Factbase::IndexedFactbase.new(Factbase.new)
    scores = [3, 5, 9]
    [plain, indexed].each { |fb| scores.each { |v| fb.insert.score = v } }
    all = [[10, 4], [4, 10], [5, 5], [1, 2], [20, 30]]
    ops = %w[gt gte lt lte]
    ops.each do |op|
      all.each do |limits|
        q = "(#{op} score $limits)"
        params = { 'limits' => limits }
        assert_equal(
          plain.query(q).each(plain, params).map(&:score),
          indexed.query(q).each(indexed, params).map(&:score),
          "#{q} with #{limits}"
        )
      end
    end
  end
end
