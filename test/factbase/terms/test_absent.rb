# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/absent'

require_relative '../../test__helper'

# Test for 'absent' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestAbsent < Factbase::Test
  def test_absent
    t = Factbase::Absent.new([:foo])
    refute(t.evaluate(fact('foo' => 41), [], Factbase.new))
    assert(t.evaluate(fact('bar' => 41), [], Factbase.new))
  end

  def test_not_enough_args
    assert_includes(
      assert_raises(StandardError) do
        Factbase::Term.new(:absent, []).evaluate(fact('a' => 1, 'b' => 0), [], Factbase.new)
      end.message,
      "Too few (0) operands for 'absent' (1 expected)"
    )
  end

  def test_too_many_args
    assert_includes(
      assert_raises(StandardError) do
        Factbase::Term.new(:absent, %i[a b]).evaluate(fact('a' => 1, 'b' => 0), [], Factbase.new)
      end.message,
      "Too many (2) operands for 'absent' (1 expected)"
    )
  end
end
