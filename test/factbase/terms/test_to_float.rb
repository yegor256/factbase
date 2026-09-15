# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_float'

require_relative '../../test__helper'

# Test for 'to_float' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToFloat < Factbase::Test
  def test_to_float
    assert_equal('Float', Factbase::ToFloat.new([3.14]).evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_rejects_invalid_value
    t = Factbase::ToFloat.new(['abc'])
    assert_includes(
      assert_raises(RuntimeError) { t.evaluate(fact, [], Factbase.new) }.message,
      "Cannot convert 'abc' to Float in (to_float ...):"
    )
  end

  def test_rejects_a_property_with_many_values
    t = Factbase::ToFloat.new([:foo])
    e =
      assert_raises(ArgumentError) do
        t.evaluate(fact('foo' => [1, 2]), [], Factbase.new)
      end
    assert_includes(e.message, 'Too many values at first position, one expected', e.message)
  end
end
