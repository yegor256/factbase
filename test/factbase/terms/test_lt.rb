# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT
#
require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/lt'

# Tests for the 'lt' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestLt < Factbase::Test
  def test_compares_less_than
    t = Factbase::Lt.new([:number, 42])
    assert(t.evaluate(fact('number' => 10), [], Factbase.new))
  end

  def test_compares_not_less_than
    t = Factbase::Lt.new([:number, 42])
    refute(t.evaluate(fact('number' => 100), [], Factbase.new))
  end
end
