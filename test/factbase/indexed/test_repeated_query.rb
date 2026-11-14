# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_absent'
require_relative '../../../lib/factbase/indexed/indexed_eq'
require_relative '../../../lib/factbase/indexed/indexed_exists'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../../lib/factbase/indexed/indexed_one'
require_relative '../../test__helper'

# Every single-property index remembers how many facts it has already scanned
# and feeds only the tail on the next call, so a repeated query over an
# unchanged factbase must not append the last fact a second time.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestRepeatedQuery < Factbase::Test
  def test_absent_feeds_every_fact_once
    _assert_stable('(absent x)', 4) { |fb, i| fb.insert.y = i }
  end

  def test_one_feeds_every_fact_once
    _assert_stable('(one y)', 4) { |fb, i| fb.insert.y = i }
  end

  def test_exists_feeds_every_fact_once
    _assert_stable('(exists y)', 4) { |fb, i| fb.insert.y = i }
  end

  def test_eq_feeds_every_fact_once
    _assert_stable('(eq y 3)', 1) { |fb, i| fb.insert.y = i }
  end

  private

  # Run the same query three times over four facts and assert the answer and
  # its size stay the expected ones, so an index that feeds nothing fails too.
  # @param [String] query The query to run three times
  # @param [Integer] count How many facts the query must find
  # @yield [Factbase, Integer] How to insert the next fact
  def _assert_stable(query, count)
    indexed = Factbase::IndexedFactbase.new(Factbase.new)
    4.times { |i| yield(indexed, i) }
    assert_equal(
      [count] * 3,
      Array.new(3) { indexed.query(query).each.to_a.size },
      "A repeated #{query} must answer #{count} every time"
    )
  end
end
