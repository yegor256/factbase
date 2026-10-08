# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/sprintf'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

class TestSprintf < Factbase::Test
  def test_sprintf
    assert_equal('hi, Jeff!', Factbase::Sprintf.new(['hi, %s!', 'Jeff']).evaluate(fact, [], Factbase.new))
  end

  def test_rejects_a_format_the_fact_does_not_have
    t = Factbase::Sprintf.new([:missing, 'Jeff'])
    e =
      assert_raises(ArgumentError) do
        t.evaluate(fact, [], Factbase.new)
      end
    assert_includes(e.message, "The format of 'sprintf' is :missing, which the fact doesn't have", e.message)
  end

  def test_rejects_invalid_format_operand
    t = Factbase::Sprintf.new(['%d', 'hello'])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact, [], Factbase.new)
      end
    assert_includes(e.message, "Cannot format [\"hello\"] with '%d' in (sprintf ...):")
    assert_includes(e.message, 'invalid value for Integer')
  end

  def test_names_the_format_when_an_operand_is_absent
    [['%d', :absent], ['%f', :absent]].each do |ops|
      t = Factbase::Sprintf.new(ops)
      assert_includes(
        assert_raises(ArgumentError) { t.evaluate(fact, [], Factbase.new) }.message,
        "The operand :absent of 'sprintf' with '#{ops[0]}' is absent in the fact"
      )
    end
  end

  def test_refuses_an_absent_operand_instead_of_printing_it_empty
    fb = Factbase.new
    fb.insert.x = 10
    e = assert_raises(StandardError) { fb.query('(eq (sprintf "%s-%s" x nope) "10-")').each.to_a }
    assert_includes(e.message, "The operand :nope of 'sprintf' with '%s-%s' is absent in the fact", e.message)
  end

  def test_rejects_missing_format_operand
    t = Factbase::Sprintf.new(['%s %s', 'hello'])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact, [], Factbase.new)
      end
    assert_includes(e.message, "Cannot format [\"hello\"] with '%s %s' in (sprintf ...):")
    assert_includes(e.message, 'too few arguments')
  end
end
