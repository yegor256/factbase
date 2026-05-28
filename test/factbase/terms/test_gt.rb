# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/gt'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
require_relative '../../test__helper'

# Tests for the 'gt' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestGt < Factbase::Test
  def test_compares_greater_than
    assert(Factbase::Gt.new([:number, 42]).evaluate(fact('number' => 100), [], Factbase.new))
  end

  def test_compares_not_greater_than
    refute(Factbase::Gt.new([:number, 42]).evaluate(fact('number' => 10), [], Factbase.new))
  end
end
