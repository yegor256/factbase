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
    if @term.operands.first.is_a?(Symbol) && _scalar?(@term.operands[1])
      if @idx[key].nil?
        @idx[key] = {}
        prop = @term.operands.first.to_s
        maps.to_a.each do |m|
          m[prop]&.each do |v|
            @idx[key][v] = [] if @idx[key][v].nil?
            @idx[key][v].append(m)
          end
        end
      end
      vv =
        if @term.operands[1].is_a?(Symbol)
          params[@term.operands[1].to_s] || []
        else
          [@term.operands[1]]
        end
      if vv.empty?
        (maps & [])
      else
        j = vv.map { |v| @idx[key][v] || [] }.reduce(&:|)
        (maps & []) | j
      end
    end
  end

  private

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end
end
