# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'not'.
class Factbase::IndexedNot
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, fb, params)
    return nil if @idx.nil?
    key = [maps.object_id, @term.operands.first, @term.op]
    entry = @idx[key]
    maps_array = maps.to_a
    if entry.nil?
      entry = { facts: nil, indexed_count: 0, yes_set: nil }
      @idx[key] = entry
    end
    if entry[:indexed_count] < maps_array.size
      yes = @term.operands.first.predict(maps, fb, params)
      if yes.nil?
        entry[:facts] = nil
        entry[:yes_set] = nil
      else
        yes_set = yes.to_a.to_set
        entry[:yes_set] = yes_set
        entry[:facts] = maps_array.reject { |m| yes_set.include?(m) }
      end
      entry[:indexed_count] = maps_array.size
    end
    r = entry[:facts]
    if r.nil?
      nil
    elsif maps.respond_to?(:ensure_copied)
      maps & r
    else
      (maps & []) | r
    end
  end
end
