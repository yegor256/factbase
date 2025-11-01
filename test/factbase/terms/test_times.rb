# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/times'

# Test for 'times' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestTimes < Factbase::Test
  def test_times
    t = Factbase::Times.new([:foo, 42])
    assert_equal(4200, t.evaluate(fact('foo' => 100), [], Factbase.new))
  end
end
