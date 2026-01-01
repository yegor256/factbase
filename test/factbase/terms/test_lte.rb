# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
#
require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/lte'

# Tests for the 'lte' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestLte < Factbase::Test
  def test_compares_less_than_or_equal
    t = Factbase::Lte.new([:number, 42])
    assert(t.evaluate(fact('number' => 10), [], Factbase.new))
    assert(t.evaluate(fact('number' => 42), [], Factbase.new))
  end

  def test_compares_not_greater_than
    t = Factbase::Lte.new([:number, 42])
    refute(t.evaluate(fact('number' => 100), [], Factbase.new))
  end
end
