# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/cached/cached_factbase'
require_relative '../../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestCachedScope < Factbase::Test
  def test_does_not_share_the_answer_of_a_subset_query
    fb = Factbase::CachedFactbase.new(Factbase.new)
    fb.insert.foo = 1
    fb.insert.foo = 2
    assert_equal(1, fb.query('(exists foo)', fb.each.to_a[0..0]).each.to_a.size)
    assert_equal(2, fb.query('(exists foo)').each.to_a.size)
  end
end
