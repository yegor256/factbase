# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
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

  def test_wraps_incompatible_type_comparison
    t = Factbase::Compare.new(:>, [42, 'hello'])
    e = assert_raises(RuntimeError) { t.evaluate(fact, [], Factbase.new) }
    assert_includes(e.message, 'Cannot compare 42 (Integer) with "hello" (String)')
    assert_includes(e.message, 'using (compare >)')
    assert_includes(e.message, 'comparison of Integer with String failed')
  end

  def test_wraps_incompatible_time_comparison
    t = Factbase::Compare.new(:<, [Time.utc(2024, 1, 1), 'yesterday'])
    e = assert_raises(RuntimeError) { t.evaluate(fact, [], Factbase.new) }
    assert_includes(e.message, 'Time')
    assert_includes(e.message, '"yesterday" (String)')
    assert_includes(e.message, 'comparison of Time with String failed')
  end
end
