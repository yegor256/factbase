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
  def test_absent_feeds_the_last_fact_once
    _assert_stable('(absent x)') { |fb, i| fb.insert.y = i }
  end

  def test_one_feeds_the_last_fact_once
    _assert_stable('(one y)') { |fb, i| fb.insert.y = i }
  end

  def test_exists_feeds_the_last_fact_once
    _assert_stable('(exists y)') { |fb, i| fb.insert.y = i }
  end

  def test_eq_feeds_the_last_fact_once
    _assert_stable('(eq y 3)') { |fb, i| fb.insert.y = i }
  end

  private

  # Run the same query three times over four facts and assert the answer stays.
  # @param [String] query The query to run three times
  # @yield [Factbase, Integer] How to insert the next fact
  def _assert_stable(query)
    indexed = Factbase::IndexedFactbase.new(Factbase.new)
    4.times { |i| yield(indexed, i) }
    sizes = Array.new(3) { indexed.query(query).each.to_a.size }
    assert_equal([sizes.first] * 3, sizes, "A repeated #{query} must not grow")
  end
end
