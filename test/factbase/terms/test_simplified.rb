# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/always'
require_relative '../../../lib/factbase/terms/never'
require_relative '../../../lib/factbase/terms/or'
require_relative '../../../lib/factbase/terms/simplified'

# Test for the 'Simplified' class.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSimplified < Factbase::Test
  def test_unique_operands_simple
    t1 = Factbase::Or.new([])
    t2 = Factbase::Or.new([])
    simplified = Factbase::Simplified.new([t1, t2])
    assert_equal(1, simplified.unique.size)
  end

  def test_unique_operands_complex
    t1 = Factbase::Or.new([Factbase::And.new([]), Factbase::And.new([])])
    t2 = Factbase::Or.new([Factbase::Or.new([]), Factbase::And.new([])])
    t3 = Factbase::Or.new([Factbase::Or.new([]), Factbase::Or.new([])])
    simplified = Factbase::Simplified.new([t1, t2, t3])
    assert_equal(3, simplified.unique.size)
  end
end
