# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSyntaxBrackets < Factbase::Test
  def test_reads_a_term_that_touches_the_next_bracket
    fb = Factbase.new
    fb.insert.foo = 1
    assert_equal(1, fb.query('(and(eq foo 1))').each.to_a.size)
  end
end
