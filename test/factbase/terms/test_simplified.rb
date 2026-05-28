# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/always'
require_relative '../../../lib/factbase/terms/never'
require_relative '../../../lib/factbase/terms/or'
require_relative '../../../lib/factbase/terms/simplified'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for the 'Simplified' class.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSimplified < Factbase::Test
  def test_unique_operands_simple
    assert_equal(1, Factbase::Simplified.new([Factbase::Or.new([]), Factbase::Or.new([])]).unique.size)
  end

  def test_unique_operands_complex
    assert_equal(
      3,
      Factbase::Simplified.new(
        [
          Factbase::Or.new([Factbase::And.new([]), Factbase::And.new([])]),
          Factbase::Or.new([Factbase::Or.new([]), Factbase::And.new([])]), Factbase::Or.new([Factbase::Or.new([]), Factbase::Or.new([])])
        ]
      ).unique.size
    )
  end
end
