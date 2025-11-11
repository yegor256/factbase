# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/compare'

# Test for the 'compare' term.
class TestCompare < Factbase::Test
  def test_evaluates_comparison
    t = Factbase::Compare.new(:>, [4, 2])
    assert(t.evaluate(fact, [], Factbase.new), 'Expected 4 > 2 to be true')
  end

  def test_evaluates_comparison_less
    t = Factbase::Compare.new(:<, [4, 2])
    refute(t.evaluate(fact, [], Factbase.new), 'Expected 2 < 4 to be true')
  end
end
