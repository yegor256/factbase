# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/eq'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
require_relative '../../test__helper'

# Tests for the 'eq' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestEq < Factbase::Test
  def test_compares_equal
    assert(Factbase::Eq.new([:number, 42]).evaluate(fact('number' => 42), [], Factbase.new))
  end

  def test_compares_not_equal
    refute(Factbase::Eq.new([:number, 42]).evaluate(fact('number' => 100), [], Factbase.new))
  end
end
