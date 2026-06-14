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
    return if @idx.nil?
    key = [maps.object_id, @term.operands.first, @term.op]
    r = nil
    if @term.operands.all? { |o| o.op == :eq } && @term.operands.size > 1 \
      && @term.operands.all? { |o| o.operands.first.is_a?(Symbol) && _scalar?(o.operands[1]) }
      props = @term.operands.map { |o| o.operands.first }.sort!
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
      r = maps.respond_to?(:repack) ? maps.repack(j) : j
    else
      fail = false
      @term.operands.each do |o|
        n = o.predict(maps, fb, params)
        if n.nil?
          fail = true
          break
        end
        if r.nil?
          r = n
        elsif n.size < r.size * 8
          small, large = n.size < r.size ? [n.to_a, r.to_a] : [r.to_a, n.to_a]
          ids = Set.new(small.map(&:object_id))
          r = large.select { |f| ids.include?(f.object_id) }
        end
        break if r.size < maps.size / 32
        break if r.size < 128
      end
      return if fail
    end
    r
  end

  private

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end

  def _all_tuples(fact, props)
    values = props.map { |p| fact[p.to_s] || [] }
    return [] if values.any?(&:empty?)
    values[0].product(*values[1..])
  end
end
