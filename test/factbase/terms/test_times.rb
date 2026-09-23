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
end
