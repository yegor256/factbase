# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'exists'.
class Factbase::IndexedExists
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, _fb, _params)
    return nil if @idx.nil?
    key = [maps.object_id, @term.operands.first, @term.op]
    entry = @idx[key]
    maps_array = maps.to_a
    if entry.nil?
      entry = { facts: [], indexed_count: 0 }
      @idx[key] = entry
    end
    if entry[:indexed_count] < maps_array.size
      prop = @term.operands.first.to_s
      maps_array[entry[:indexed_count]..].each do |m|
        entry[:facts] << m unless m[prop].nil?
      end
      entry[:indexed_count] = maps_array.size
    end
    (maps & []) | entry[:facts]
  end
end
