# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'lt'.
class Factbase::IndexedLt
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, _fb, params, _context = [], _tail = [])
    op1, op2 = @term.operands
    return unless op1.is_a?(Symbol) && _scalar?(op2)
    prop = op1.to_s
    target = op2.is_a?(Symbol) ? params[op2.to_s]&.first : op2
    return maps || [] if target.nil?
    key = [maps.object_id, prop, :facts]
    @idx[key] ||= { facts: [], count: 0 }
    entry = @idx[key]
    _feed(maps.to_a, entry, prop)
    matched = _search(entry, target)
    maps.respond_to?(:repack) ? maps.repack(matched) : matched
  end

  private

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end

  def _feed(facts, entry, prop)
    return unless entry[:count] < facts.size
    facts[entry[:count]..].each do |fact|
      fact[prop]&.each do |v|
        entry[:facts] << [v, fact]
      end
    end
    entry[:facts].sort_by! { |pair| pair[0] }
    entry[:count] = facts.size
  end

  def _search(entry, target)
    idx = entry[:facts].bsearch_index { |v, _| v >= target }
    res = idx.nil? ? entry[:facts] : entry[:facts][0...idx]
    res.map { |_, f| f }.uniq(&:object_id)
  end
end
