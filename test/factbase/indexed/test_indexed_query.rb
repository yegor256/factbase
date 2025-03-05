# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'

# Query test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestIndexedQuery < Factbase::Test
  def test_queries_many_times
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    total = 5
    total.times { fb.insert }
    total.times do
      assert_equal(5, fb.query('(always)').each.to_a.size)
    end
  end

  def test_aggregates_too
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    f = fb.insert
    f.foo = 42
    f.hello = 1
    assert_equal(0, fb.query('(nil (agg (exists hello) (min foo)))').each.to_a.size)
  end

  def test_deletes_too
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.foo = 1
    fb.query('(eq foo 1)').delete!
    assert_equal(0, fb.query('(always)').each.to_a.size)
  end
end
