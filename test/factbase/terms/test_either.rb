# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/either'

# Test for the 'either' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestEither < Factbase::Test
  def test_either_first_nil
    t = Factbase::Either.new([nil, Factbase::Always.new])
    assert_equal([true], t.evaluate(fact, [], Factbase.new))
  end

  def test_either_first_not_nil
    t = Factbase::Either.new([Factbase::Never.new, Factbase::Always.new])
    assert_equal([false], t.evaluate(fact, [], Factbase.new))
  end
end
