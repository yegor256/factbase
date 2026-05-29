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

  def test_rejects_invalid_format_operand
    t = Factbase::Sprintf.new(['%d', 'hello'])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact, [], Factbase.new)
      end
    assert_includes(e.message, "Cannot format [\"hello\"] with '%d' in (sprintf ...):")
    assert_includes(e.message, 'invalid value for Integer')
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
