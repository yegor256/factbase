# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/or'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/syntax'
require_relative '../../test__helper'

# Test for the 'or' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestOr < Factbase::Test
  def test_or_true
    assert(Factbase::Or.new([Factbase::Always.new([]), Factbase::Never.new([])]).evaluate(fact, [], Factbase.new))
  end

  def test_or_false
    refute(Factbase::Or.new([Factbase::Never.new([]), Factbase::Never.new([])]).evaluate(fact, [], Factbase.new))
  end

  def test_parses_a_non_term_operand
    assert_equal(%((or foo (eq a 1))), Factbase::Syntax.new(%((or foo (eq a 1)))).to_term.to_s)
  end

  def test_names_the_bad_operand_when_evaluating
    fb = Factbase.new
    fb.insert.foo = 'x'
    assert_includes(
      assert_raises(StandardError) { fb.query('(or foo (eq a 1))').each.to_a }.message,
      'Boolean is expected, while String received from foo'
    )
  end
end
