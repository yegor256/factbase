# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT
#
require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/gt'

# Tests for the 'gt' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestGt < Factbase::Test
  def test_compares_greater_than
    t = Factbase::Gt.new([:number, 42])
    assert(t.evaluate(fact('number' => 100), [], Factbase.new))
  end

  def test_compares_not_greater_than
    t = Factbase::Gt.new([:number, 42])
    refute(t.evaluate(fact('number' => 10), [], Factbase.new))
  end
end
