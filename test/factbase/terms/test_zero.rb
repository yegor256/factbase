# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/zero'

# Test for 'zero' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestZero < Factbase::Test
  def test_zero
    t = Factbase::Zero.new([:foo])
    assert(t.evaluate(fact('foo' => [0]), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [10, 5, 6, -8, 'hey', 0, 9, 'fdsf']), [], Factbase.new))
    refute(t.evaluate(fact('foo' => [100]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => []), [], Factbase.new))
    refute(t.evaluate(fact('bar' => []), [], Factbase.new))
  end
end
