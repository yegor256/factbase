# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/compare'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for the 'compare' term.
class TestCompare < Factbase::Test
  def test_evaluates_comparison
    assert(Factbase::Compare.new(:>, [4, 2]).evaluate(fact, [], Factbase.new), 'Expected 4 > 2 to be true')
  end

  def test_evaluates_comparison_less
    refute(Factbase::Compare.new(:<, [4, 2]).evaluate(fact, [], Factbase.new), 'Expected 2 < 4 to be true')
  end
end
