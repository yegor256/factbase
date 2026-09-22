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

  def test_rejects_infinite_result
    t = Factbase::Times.new(%i[foo foo])
    assert_includes(
      assert_raises(ArgumentError) { t.evaluate(fact('foo' => 1e300), [], Factbase.new) }.message,
      'not a finite number'
    )
  end
end
