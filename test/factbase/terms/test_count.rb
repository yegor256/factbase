# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/count'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'count' term.
# Author:: Vlodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestCount < Factbase::Test
  def test_count_several
    assert_equal(2, Factbase::Count.new([]).evaluate(fact, { 'first' => 1, 'second' => 2 }, Factbase.new))
  end

  def test_count_emptyseveral
    assert_equal(0, Factbase::Count.new([]).evaluate(fact, {}, Factbase.new))
  end
end
