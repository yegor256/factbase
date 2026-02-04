# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/fact'
require_relative '../../../lib/factbase/indexed/indexed_fact'

# Fact test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedFact < Factbase::Test
  def test_updates_origin
    origin = Factbase::Fact.new({})
    fact = Factbase::IndexedFact.new(origin, {}, Set.new)
    fact.foo = 42
    refute_nil(origin['foo'])
    assert_equal(42, origin.foo)
  end

  def test_invalidates_index_of_existing_fact
    fresh = Set.new
    idx = { 'foo' => 42 }
    fb = Factbase::Fact.new({})
    fact = Factbase::IndexedFact.new(fb, idx, fresh)
    fact.foo = 42
    assert_empty(idx, 'Index must be cleared because the fact is not fresh')
  end
end
