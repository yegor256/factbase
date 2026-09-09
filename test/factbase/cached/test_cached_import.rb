# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/cached/cached_factbase'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestCachedImport < Factbase::Test
  def test_sees_imported_facts_after_a_query
    src = Factbase.new
    src.insert.foo = 42
    fb = Factbase::CachedFactbase.new(Factbase.new)
    assert_empty(fb.query('(exists foo)').each.to_a)
    fb.import(src.export)
    assert_equal(1, fb.query('(exists foo)').each.to_a.size)
  end
end
