# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/times'

require_relative '../../test__helper'

# Test for 'times' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTimes < Factbase::Test
  def test_times
    assert_equal(4200, Factbase::Times.new([:foo, 42]).evaluate(fact('foo' => 100), [], Factbase.new))
  end

  def test_rejects_a_string_as_the_first_operand
    assert_includes(
      assert_raises(ArgumentError) do
        Factbase::Times.new(%i[foo bar]).evaluate(fact('foo' => 'x', 'bar' => 3), [], Factbase.new)
      end.message,
      'Cannot apply times to x (String)'
    )
  end

  def test_does_not_repeat_a_string
    fb = Factbase.new
    f = fb.insert
    f.b = 'x'
    f.a = 3
    assert_includes(
      assert_raises(StandardError) { fb.query('(as z (times b a))').each.to_a }.message,
      'Cannot apply times to'
    )
  end

  def test_rejects_a_time_as_the_first_operand
    e =
      assert_raises(ArgumentError) do
        Factbase::Times.new([:foo, 2]).evaluate(fact('foo' => Time.utc(2026, 1, 1)), [], Factbase.new)
      end
    assert_includes(e.message, 'Cannot apply times to')
    assert_includes(e.message, '(Time)')
  end
end
