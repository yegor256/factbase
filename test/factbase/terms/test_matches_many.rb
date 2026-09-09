# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestMatchesMany < Factbase::Test
  def test_matches_any_value_of_the_property
    fb = Factbase.new
    f = fb.insert
    f.foo = 'aa'
    f.foo = 'bb'
    assert_equal(1, fb.query('(matches foo "bb")').each.to_a.size)
  end
end
