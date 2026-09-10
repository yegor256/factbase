# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSyntaxQuotes < Factbase::Test
  def test_keeps_a_quote_of_the_other_kind_inside_a_literal
    fb = Factbase.new
    fb.insert.foo = "Jeff's"
    assert_equal(1, fb.query('(eq foo "Jeff\'s")').each.to_a.size)
  end

  def test_does_not_split_a_literal_with_two_intruding_quotes
    fb = Factbase.new
    fb.insert.foo = 'a" "b'
    assert_equal(1, fb.query(%q{(eq foo 'a" "b')}).each.to_a.size)
  end
end
