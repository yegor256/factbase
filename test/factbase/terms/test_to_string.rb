# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_string'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'to_string' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToString < Factbase::Test
  def test_to_str
    assert_equal('String', Factbase::ToString.new([Time.now]).evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_rejects_a_property_with_many_values
    t = Factbase::ToString.new([:foo])
    e =
      assert_raises(ArgumentError) do
        t.evaluate(fact('foo' => [1, 2]), [], Factbase.new)
      end
    assert_includes(e.message, 'Too many values at first position, one expected', e.message)
  end
end
