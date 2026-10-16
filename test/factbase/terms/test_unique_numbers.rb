# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestUniqueNumbers < Factbase::Test
  def test_counts_an_integer_and_the_equal_float_as_one_value
    fb = Factbase.new
    first = fb.insert
    first.x = 1
    second = fb.insert
    second.x = 1.0
    maps = [first, second]
    term = Factbase::Term.new(:unique, [:x])
    assert(term.evaluate(first, maps, fb))
    refute(term.evaluate(second, maps, fb))
  end
end
