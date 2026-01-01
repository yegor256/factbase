# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/first'

# Test for 'first' term.
# Author:: Vlodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestFirst < Factbase::Test
  def test_first_several
    t = Factbase::First.new([:first])
    res = t.evaluate(fact, [{ 'first' => 1 }], Factbase.new)
    assert_equal(1, res)
  end

  def test_first_absent
    t = Factbase::First.new([:absent])
    res = t.evaluate(fact, {}, Factbase.new)
    assert_nil(res)
  end
end
