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
class TestIndexedAndOrder < Factbase::Test
  def test_answers_in_insertion_order
    origin = Factbase.new
    indexed = Factbase::IndexedFactbase.new(Factbase.new)
    [[3, 30], [1, 10], [2, 20]].each do |a, b|
      [origin, indexed].each do |fb|
        f = fb.insert
        f.a = a
        f.b = b
      end
    end
    query = '(and (eq a $a) (eq b $b))'
    params = { 'a' => [1, 2, 3], 'b' => [10, 20, 30] }
    assert_equal(
      origin.query(query).each(origin, params).to_a.map(&:a),
      indexed.query(query).each(indexed, params).to_a.map(&:a)
    )
  end
end
