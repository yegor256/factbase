# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/one'

# Test for 'one' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestOne < Factbase::Test
  def test_one
    t = Factbase::One.new([:foo])
    assert(t.evaluate(fact('foo' => 1), [], Factbase.new))
    assert(t.evaluate(fact('foo' => '1234'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [1]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => nil), [], Factbase.new))
    refute(t.evaluate(fact('foo' => [1, 3, 5]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => []), [], Factbase.new))
  end
end
