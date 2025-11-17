# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'gt'.
class Factbase::IndexedGt
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, _fb, params)
    return nil if @idx.nil?
    return unless @term.operands.first.is_a?(Symbol) && _scalar?(@term.operands[1])
    prop = @term.operands.first.to_s
    cache_key = [maps.object_id, @term.operands.first, :sorted]
    if @idx[cache_key].nil?
      @idx[cache_key] = []
      maps.to_a.each do |m|
        values = m[prop]
        next if values.nil?
        values.each do |v|
          @idx[cache_key] << [v, m]
        end
      end
      @idx[cache_key].sort_by! { |pair| pair[0] }
    end
    threshold = @term.operands[1].is_a?(Symbol) ? params[@term.operands[1].to_s]&.first : @term.operands[1]
    return nil if threshold.nil?
    i = @idx[cache_key].bsearch_index { |pair| pair[0] > threshold } || @idx[cache_key].size
    result = @idx[cache_key][i..].map { |pair| pair[1] }.uniq
    (maps & []) | result
  end

  private

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end
end
