# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/or'

# Test for the 'or' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestOr < Factbase::Test
  def test_or_true
    assert(Factbase::Or.new([Factbase::Always.new([]), Factbase::Never.new([])]).evaluate(fact, [], Factbase.new))
  end

  def test_or_false
    refute(Factbase::Or.new([Factbase::Never.new([]), Factbase::Never.new([])]).evaluate(fact, [], Factbase.new))
  end
end
