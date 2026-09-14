# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/syntax'
require_relative '../../test__helper'

# Test for sorting over values that cannot be compared.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSortedMixed < Factbase::Test
  def test_explains_what_it_could_not_compare
    fb = Factbase.new
    fb.insert.foo = 1
    fb.insert.foo = 'a'
    e =
      assert_raises(StandardError, 'mixed types in sorted do not explain themselves') do
        fb.query('(sorted foo (always))').each.to_a
      end
    assert_includes(e.message, "in the 'foo' property")
    assert_includes(e.message, 'String')
    assert_includes(e.message, 'Integer')
  end
end
