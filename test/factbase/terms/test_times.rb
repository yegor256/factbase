# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/times'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'times' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTimes < Factbase::Test
  def test_times
    assert_equal(4200, Factbase::Times.new([:foo, 42]).evaluate(fact('foo' => 100), [], Factbase.new))
  end

  def test_refuses_to_repeat_a_string
    t = Factbase::Times.new([:foo, 3])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact('foo' => 'x'), [], Factbase.new)
      end
    assert_includes(e.message, 'only numbers and times can be used', e.message)
  end

  def test_refuses_number_times_string
    t = Factbase::Times.new([3, :foo])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact('foo' => 'x'), [], Factbase.new)
      end
    assert_includes(e.message, 'only numbers and times can be used', e.message)
  end

  def test_refuses_two_strings
    t = Factbase::Times.new(%i[foo bar])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact('foo' => 'x', 'bar' => 'y'), [], Factbase.new)
      end
    assert_includes(e.message, 'only numbers and times can be used', e.message)
  end

  def test_query_refuses_to_repeat_string
    fb = Factbase.new
    f = fb.insert
    f.a = 3
    f.b = 'x'
    assert_includes(
      assert_raises(RuntimeError) do
        fb.query('(and (always) (as z (times b a)))').each.to_a
      end.message,
      'only numbers and times can be used'
    )
  end
end
