# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/first'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'first' term.
# Author:: Vlodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestFirst < Factbase::Test
  def test_first_several
    assert_equal(1, Factbase::First.new([:first]).evaluate(fact, [{ 'first' => 1 }], Factbase.new))
  end

  def test_first_absent
    assert_nil(Factbase::First.new([:absent]).evaluate(fact, {}, Factbase.new))
  end
end
