# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/when'

# Test for the 'when' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestWhen < Factbase::Test
  def test_when_parametrized
    [
      [Factbase::Always.new, Factbase::Always.new, true],
      [Factbase::Never.new,  Factbase::Always.new, true],
      [Factbase::Never.new,  Factbase::Never.new,  true],
      [Factbase::Always.new, Factbase::Never.new,  false]
    ].each do |first, second, should_pass|
      t = Factbase::When.new([first, second])
      if should_pass
        assert(t.evaluate(fact, [], Factbase.new))
      else
        refute(t.evaluate(fact, [], Factbase.new))
      end
    end
  end
end
