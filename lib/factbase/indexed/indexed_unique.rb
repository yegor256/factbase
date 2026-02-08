# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'unique'.
# @todo #249:30min Improve prediction for 'unique' term. Current prediction is quite naive and
#  returns many false positives because it just filters facts which have exactly the same set
#  of keys regardless the values. We should introduce more smart prediction.
class Factbase::IndexedUnique
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
      props = @term.operands.map(&:to_s)
      maps_array[entry[:indexed_count]..].each do |m|
        entry[:facts] << m if props.all? { |p| !m[p].nil? }
      end
      entry[:indexed_count] = maps_array.size
    end
    if maps.respond_to?(:ensure_copied)
      maps & entry[:facts]
    else
      (maps & []) | entry[:facts]
    end
  end
end
