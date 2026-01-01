# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/count'

# Test for 'count' term.
# Author:: Vlodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestCount < Factbase::Test
  def test_count_several
    t = Factbase::Count.new([])
    res = t.evaluate(fact, { 'first' => 1, 'second' => 2 }, Factbase.new)
    assert_equal(2, res)
  end

  def test_count_emptyseveral
    t = Factbase::Count.new([])
    res = t.evaluate(fact, {}, Factbase.new)
    assert_equal(0, res)
  end
end
