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

  def test_too_many_args
    assert_includes(
      assert_raises(StandardError) do
        Factbase::Term.new(:exists, %i[a b]).evaluate(fact('a' => 1, 'b' => 0), [], Factbase.new)
      end.message,
      "Too many (2) operands for 'exists' (1 expected)"
    )
  end
end
