# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_integer'

require_relative '../../test__helper'

# Test for 'to_integer' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToInteger < Factbase::Test
  def test_to_integer
    assert_equal('Integer', Factbase::ToInteger.new([42]).evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_truncates_float
    assert_equal(5_961_600, Factbase::ToInteger.new([[5_961_600.0]]).evaluate(fact, [], Factbase.new))
  end

  def test_rejects_invalid_value
    t = Factbase::ToInteger.new(['abc'])
    assert_includes(
      assert_raises(RuntimeError) { t.evaluate(fact, [], Factbase.new) }.message,
      "Cannot convert 'abc' to Integer in (to_integer ...):"
    )
  end

  def test_rejects_a_property_with_many_values
    t = Factbase::ToInteger.new([:foo])
    e =
      assert_raises(ArgumentError) do
        t.evaluate(fact('foo' => [1, 2]), [], Factbase.new)
      end
    assert_includes(e.message, 'Too many values at first position, one expected', e.message)
  end
end
