# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/and'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/syntax'
require_relative '../../test__helper'

# Test for the 'and' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestAnd < Factbase::Test
  def test_and_true
    assert(Factbase::And.new([Factbase::Always.new([]), Factbase::Always.new([])]).evaluate(fact, [], Factbase.new))
  end

  def test_and_false
    refute(Factbase::And.new([Factbase::Always.new([]), Factbase::Never.new([])]).evaluate(fact, [], Factbase.new))
  end

  def test_parses_a_non_term_operand
    assert_equal(%((and (eq a 1) 5)), Factbase::Syntax.new(%((and (eq a 1) 5))).to_term.to_s)
  end

  def test_reports_a_single_non_term_operand
    fb = Factbase.new
    fb.insert.name = 'alice'
    ['(and 42)', '(or 42)'].each do |q|
      assert_includes(
        assert_raises(StandardError, q) do
          fb.query(q).each.to_a
        end.message, 'Boolean is expected, while Integer received from 42', q
      )
    end
  end
end
