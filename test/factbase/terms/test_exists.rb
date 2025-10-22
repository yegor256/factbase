# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/exists'

# Test for 'absent' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestExists < Factbase::Test
  def test_exists
    t = Factbase::Exists.new([:foo])
    assert(t.evaluate(fact('foo' => 41), [], Factbase.new))
    refute(t.evaluate(fact('bar' => 41), [], Factbase.new))
  end
end
