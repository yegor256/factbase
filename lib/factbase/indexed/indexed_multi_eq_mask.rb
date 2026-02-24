# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed for multiple 'eq' mask terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Author:: Philip Belousov (belousovfilip@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::IndexedMultiEqMask
  def initialize(term, idx, mask_size)
    @term = term
    @idx = idx
    @mask_size = mask_size
  end

  def mask(maps, params)
    props = @term.operands.map { |o| o.operands.first.to_s }.sort
    entry = _entry(maps, props)
    _feed(maps, entry, props)
    _build_masks(entry, params)
  end

  private

  def _entry(maps, props)
    key = [maps.object_id, props, :multi_and_eq_mask]
    @idx[key] ||= { facts: {}, count: 0 }
  end

  def _feed(maps, entry, props)
    offset = entry[:count]
    return if offset >= maps.size
    facts = entry[:facts]
    m_size = @mask_size
    (offset...maps.size).each do |abs_idx|
      item = maps[abs_idx]
      b_idx, bit_pos = abs_idx.divmod(m_size)
      bit = 1 << bit_pos
      props.each do |p|
        item[p]&.each do |v|
          (facts[[p, v]] ||= {})[b_idx] = (facts[[p, v]][b_idx] || 0) | bit
        end
      end
    end
    entry[:count] = maps.size
  end

  def _build_masks(entry, params)
    facts = entry[:facts]
    @term.operands.reduce(nil) do |res, op|
      prop, raw = op.operands
      val = params.respond_to?(:resolve) ? params.resolve(raw).first : raw
      cur = facts[[prop.to_s, val]] || {}
      return {} if cur.empty?
      next cur if res.nil?
      matches = {}
      target, source = res.size < cur.size ? [res, cur] : [cur, res]
      target.each do |idx, mask|
        m = mask & (source[idx] || 0)
        matches[idx] = m unless m.zero?
      end
      return {} if matches.empty?
      matches
    end || {}
  end
end
