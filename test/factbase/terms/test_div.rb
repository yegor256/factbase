# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/div'

# Test for 'div' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestDiv < Factbase::Test
  def test_div_numbers
    t = Factbase::Div.new([:balance, 100])
    assert_equal(420, t.evaluate(fact('balance' => 42_000), [], Factbase.new))
  end

  def test_div_times_not_supported
    t = Factbase::Div.new([:warranty, Time.new(2024, 1, 1)])
    assert_includes(
      assert_raises(NoMethodError) do
        t.evaluate(fact('warranty' => Time.new(2026, 1, 1)), [], Factbase.new)
      end.message,
      'undefined method'
    )
  end
end
