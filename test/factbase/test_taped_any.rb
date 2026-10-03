# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase/lazy_taped_array'
require_relative '../../lib/factbase/taped'
require_relative '../test__helper'

class TestTapedAny < Factbase::Test
  def test_takes_a_pattern_the_way_the_lazy_one_does
    assert(
      Factbase::Taped::TapedArray.new([1, 2, 3], 0, []).any?(2),
      'a pattern must be accepted, the way LazyTapedArray accepts it'
    )
  end

  def test_still_takes_a_block
    assert(Factbase::Taped::TapedArray.new([1, 2, 3], 0, []).any?(&:positive?), 'a block still works')
  end
end
