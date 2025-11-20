# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/and'

# Test for the 'and' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestAnd < Factbase::Test
  def test_and_true
    assert(Factbase::And.new([Factbase::Always.new([]), Factbase::Always.new([])]).evaluate(fact, [], Factbase.new))
  end

  def test_and_false
    refute(Factbase::And.new([Factbase::Always.new([]), Factbase::Never.new([])]).evaluate(fact, [], Factbase.new))
  end
end
