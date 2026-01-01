# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'and'.
class Factbase::IndexedAnd
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, fb, params)
    return nil if @idx.nil?
    key = [maps.object_id, @term.operands.first, @term.op]
    r = nil
    if @term.operands.all? { |o| o.op == :eq } && @term.operands.size > 1 \
      && @term.operands.all? { |o| o.operands.first.is_a?(Symbol) && _scalar?(o.operands[1]) }
      props = @term.operands.map { |o| o.operands.first }.sort
      key = [maps.object_id, props, :multi_and_eq]
      entry = @idx[key]
      maps_array = maps.to_a
      if entry.nil?
        entry = { index: {}, indexed_count: 0 }
        @idx[key] = entry
      end
      if entry[:indexed_count] < maps_array.size
        maps_array[entry[:indexed_count]..].each do |m|
          _all_tuples(m, props).each do |t|
            entry[:index][t] ||= []
            entry[:index][t] << m
          end
        end
        entry[:indexed_count] = maps_array.size
      end
      tuples = Enumerator.product(
        *@term.operands.sort_by { |o| o.operands.first }.map do |o|
          if o.operands[1].is_a?(Symbol)
            params[o.operands[1].to_s] || []
          else
            [o.operands[1]]
          end
        end
      )
      j = tuples.flat_map { |t| entry[:index][t] || [] }.uniq(&:object_id)
      r =
        if maps.respond_to?(:inserted)
          Factbase::Taped.new(j, inserted: maps.inserted, deleted: maps.deleted, added: maps.added)
        else
          j
        end
    else
      @term.operands.each do |o|
        n = o.predict(maps, fb, params)
        break if n.nil?
        if r.nil?
          r = n
        elsif n.size < r.size * 8 # to skip some obvious matchings
          r &= n.to_a
        end
        break if r.size < maps.size / 32 # it's already small enough
        break if r.size < 128 # it's obviously already small enough
      end
    end
    r
  end

  private

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end

  def _all_tuples(fact, props)
    prop = props.first.to_s
    tuples = []
    tuples += (fact[prop] || []).zip
    if props.size > 1
      tails = _all_tuples(fact, props[1..])
      ext = []
      tuples.each do |t|
        tails.each do |tail|
          ext << (t + tail)
        end
      end
      tuples = ext
    end
    tuples
  end
end
