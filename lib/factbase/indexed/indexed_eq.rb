# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'eq'.
class Factbase::IndexedEq
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, _fb, params)
    return nil if @idx.nil?
    key = [maps.object_id, @term.operands.first, @term.op]
    return unless @term.operands.first.is_a?(Symbol) && _scalar?(@term.operands[1])
    entry = @idx[key]
    maps_array = maps.to_a
    if entry.nil?
      entry = { index: {}, indexed_count: 0 }
      @idx[key] = entry
    end
    if entry[:indexed_count] < maps_array.size
      prop = @term.operands.first.to_s
      maps_array[entry[:indexed_count]..].each do |m|
        m[prop]&.each do |v|
          entry[:index][v] ||= []
          entry[:index][v] << m
        end
      end
      entry[:indexed_count] = maps_array.size
    end
    vv =
      if @term.operands[1].is_a?(Symbol)
        params[@term.operands[1].to_s] || []
      else
        [@term.operands[1]]
      end
    j = vv.flat_map { |v| entry[:index][v] || [] }.uniq(&:object_id)
    if maps.respond_to?(:inserted)
      Factbase::Taped.new(j, inserted: maps.inserted, deleted: maps.deleted, added: maps.added)
    else
      j
    end
  end

  private

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end
end
