# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'indexed_multi_eq_mask'

# Indexed term 'and'.
class Factbase::IndexedAnd
  def initialize(term, idx, mask_size)
    @term = term
    @idx = idx
    @mask_size = mask_size
  end

  def predict(maps, fb, params)
    return nil if @idx.nil?
    r = nil
    if _use_multi_eq?
      buckets_mask = Factbase::IndexedMultiEqMask.new(@term, @idx, @mask_size).mask(maps, params)
      matches = _filter_by_mask(maps, buckets_mask, @mask_size)
      r = maps.respond_to?(:repack) ? maps.repack(matches) : matches
    else
      max_size = maps.size * 0.95
      @term.operands.each do |o|
        n = o.predict(maps, fb, params)
        break if n.nil?
        next if n.size >= max_size
        if r.nil?
          r = n
        else
          r, n = n, r if r.size > n.size
          ids = n.to_set(&:object_id)
          r = r.select { |f| ids.include?(f.object_id) }
        end
        break if r.size < maps.size / 32 # it's already small enough
        break if r.size < 128 # it's obviously already small enough
      end
    end
    r
  end

  private

  def _use_multi_eq?
    @term.operands.size > 1 && @term.operands.all? do |op|
      op.op == :eq && op.operands[0].is_a?(Symbol) && _scalar?(op.operands[1])
    end
  end

  def _filter_by_mask(maps, buckets, m_size)
    return [] if buckets.empty?
    matches = []
    buckets.each do |b_idx, mask|
      offset = b_idx * m_size
      while mask.positive?
        abs_idx = offset + (mask & -mask).bit_length - 1
        matches << maps[abs_idx]
        mask &= (mask - 1)
      end
    end
    matches
  end

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end
end
