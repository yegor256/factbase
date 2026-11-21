# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/exists'

require_relative '../../test__helper'

# Test for 'absent' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestExists < Factbase::Test
  def test_exists
    t = Factbase::Exists.new([:foo])
    assert(t.evaluate(fact('foo' => 41), [], Factbase.new))
    refute(t.evaluate(fact('bar' => 41), [], Factbase.new))
  end

  def test_refuses_a_non_symbol_operand
    fb = Factbase.new
    fb.insert.x = 1
    e = assert_raises(RuntimeError) { fb.query('(exists 42)').each.to_a }
    assert_includes(e.message, "A symbol expected at #0, but '42' (Integer) provided", e.message)
  end
end
