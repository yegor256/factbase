# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT
#
require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/eq'

# Tests for the 'eq' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestEq < Factbase::Test
  def test_compares_equal
    t = Factbase::Eq.new([:number, 42])
    assert(t.evaluate(fact('number' => 42), [], Factbase.new))
  end

  def test_compares_not_equal
    t = Factbase::Eq.new([:number, 42])
    refute(t.evaluate(fact('number' => 100), [], Factbase.new))
  end
end
