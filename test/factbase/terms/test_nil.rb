# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/nil'

# Test for 'nil' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestNil < Factbase::Test
  def test_nil
    t = Factbase::Nil.new([:foo])
    assert(t.evaluate(fact('foo' => nil), [], Factbase.new))
    refute(t.evaluate(fact('foo' => true), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 'bar'), [], Factbase.new))
  end
end
