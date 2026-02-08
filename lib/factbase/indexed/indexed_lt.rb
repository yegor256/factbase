# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'lt'.
class Factbase::IndexedLt
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, _fb, params)
    return nil if @idx.nil?
    return unless @term.operands.first.is_a?(Symbol) && _scalar?(@term.operands[1])
    prop = @term.operands.first.to_s
    cache_key = [maps.object_id, @term.operands.first, :sorted]
    entry = @idx[cache_key]
    maps_array = maps.to_a
    if entry.nil?
      entry = { sorted: [], indexed_count: 0 }
      @idx[cache_key] = entry
    end
    if entry[:indexed_count] < maps_array.size
      new_pairs = []
      maps_array[entry[:indexed_count]..].each do |m|
        values = m[prop]
        next if values.nil?
        values.each do |v|
          new_pairs << [v, m]
        end
      end
      unless new_pairs.empty?
        entry[:sorted].concat(new_pairs)
        entry[:sorted].sort_by! { |pair| pair[0] }
      end
      entry[:indexed_count] = maps_array.size
    end

    threshold = @term.operands[1].is_a?(Symbol) ? params[@term.operands[1].to_s]&.first : @term.operands[1]
    return nil if threshold.nil?
    i = entry[:sorted].bsearch_index { |pair| pair[0] >= threshold } || entry[:sorted].size
    result = entry[:sorted][0...i].map { |pair| pair[1] }.uniq
    if maps.respond_to?(:ensure_copied)
      maps & result
    else
      (maps & []) | result
    end
  end

  private

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end
end
