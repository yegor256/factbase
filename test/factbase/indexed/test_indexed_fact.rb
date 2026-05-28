# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/fact'
require_relative '../../../lib/factbase/indexed/indexed_fact'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Fact test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedFact < Factbase::Test
  def test_updates_origin
    origin = Factbase::Fact.new({})
    Factbase::IndexedFact.new(origin, {}, Set.new).foo = 42
    refute_nil(origin['foo'])
    assert_equal(42, origin.foo)
  end

  def test_invalidates_index_of_existing_fact
    idx = { 'foo' => 42 }
    Factbase::IndexedFact.new(Factbase::Fact.new({}), idx, Set.new).foo = 42
    assert_empty(idx, 'Index must be cleared because the fact is not fresh')
  end
end
