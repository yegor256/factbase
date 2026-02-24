# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/indexed/indexed_and'

class TestIndexedMultiEqMask < Factbase::Test
  def test_builds_mask_directly
    term = Factbase::Term.new(
      :and,
      [
        Factbase::Term.new(:eq, [:color, 'red']),
        Factbase::Term.new(:eq, [:size, 'big'])
      ]
    )
    idx = {}
    mask_size = 2
    term = Factbase::IndexedMultiEqMask.new(term, idx, mask_size)
    maps = [
      { 'color' => ['red'], 'size' => ['big'] },
      { 'color' => ['blue'], 'size' => ['big'] },
      { 'color' => ['red'], 'size' => ['big'] }
    ]
    buckets = term.mask(maps, {})
    indexes = _indexes_by_mask(buckets, mask_size)
    assert_equal([0, 2], indexes)
  end

  private

  def _indexes_by_mask(buckets, m_size)
    return [] if buckets.empty?
    matches = []
    buckets.each do |b_idx, mask|
      offset = b_idx * m_size
      while mask.positive?
        abs_idx = offset + (mask & -mask).bit_length - 1
        matches << abs_idx
        mask &= (mask - 1)
      end
    end
    matches.sort!
  end
end
