# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/either'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for the 'either' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestEither < Factbase::Test
  def test_either_first_nil
    assert_equal([true], Factbase::Either.new([nil, Factbase::Always.new]).evaluate(fact, [], Factbase.new))
  end

  def test_either_first_not_nil
    assert_equal(
      [false],
      Factbase::Either.new([Factbase::Never.new, Factbase::Always.new]).evaluate(fact, [], Factbase.new)
    )
  end
end
