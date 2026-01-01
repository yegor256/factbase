# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/gte'

# Tests for the 'gte' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestGte < Factbase::Test
  def test_compares_greater_than_or_equal
    t = Factbase::Gte.new([:number, 42])
    assert(t.evaluate(fact('number' => 42), [], Factbase.new))
    assert(t.evaluate(fact('number' => 100), [], Factbase.new))
  end

  def test_compares_not_greater_than_or_equal
    t = Factbase::Gte.new([:number, 42])
    refute(t.evaluate(fact('number' => 41), [], Factbase.new))
  end
end
