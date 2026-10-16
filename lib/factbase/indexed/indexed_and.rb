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
      if entry.nil? || entry[:indexed_count] > maps_array.size
        entry = { index: {}, indexed_count: 0, pos: {}.compare_by_identity }
        @idx[key] = entry
      end
      if entry[:indexed_count] < maps_array.size
        maps_array[entry[:indexed_count]..].each_with_index do |m, i|
          entry[:pos][m] = entry[:indexed_count] + i
          _all_tuples(m, props).each do |t|
            key = t.map { |value| normalize(value) }
            entry[:index][key] ||= []
            entry[:index][key] << m
          end
        end
        entry[:indexed_count] = maps_array.size
      end
      tuples = Enumerator.product(
        *@term.operands.sort_by { |o| o.operands.first }.map do |o|
          _resolve(o.operands[1], params)
        end
      )
      j =
        tuples.flat_map do |t|
          entry[:index][t.map { |value| normalize(value) }] || []
        end.uniq(&:object_id).sort_by { |m| entry[:pos][m] }
      r = maps.respond_to?(:repack) ? maps.repack(j) : j
    else
      fail = false
      copying = %i[head sorted inverted]
      @term.operands.each do |o|
        next if copying.include?(o.op)
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
          r = maps.repack(r) if maps.respond_to?(:repack)
        end
        break if r.size < maps.size / 32
        break if r.size < 128
      end
      return if fail
    end
    r
  end

  private

  # Can the index resolve this operand on its own?
  #
  # A Symbol is a query parameter only when it starts with a dollar sign.
  # Without one it names another property, which the index has no value for,
  # so the full scan has to compare the two properties itself.
  #
  # @param [Object] item The second operand of the term
  # @return [Boolean] TRUE if the index can take it
  def _scalar?(item)
    return item.to_s.start_with?('$') if item.is_a?(Symbol)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) ||
      item.is_a?(TrueClass) || item.is_a?(FalseClass)
  end

  def _resolve(operand, params)
    return [operand] unless operand.is_a?(Symbol)
    value = params[operand.to_s]
    value = params[operand.to_s[1..]] if value.nil? && operand.to_s.start_with?('$') && params.respond_to?(:[])
    return [] if value.nil?
    value.respond_to?(:each) ? value : [value]
  end

  def _all_tuples(fact, props)
    values = props.map { |p| fact[p.to_s] || [] }
    return [] if values.any?(&:empty?)
    values[0].product(*values[1..])
  end

  def normalize(value)
    return Rational(value) if value.is_a?(Integer) || (value.is_a?(Float) && value.finite?)
    value
  end
end
