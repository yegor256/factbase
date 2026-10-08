# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'eq' that uses the hash-based inverted index for fast equality lookups.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::IndexedEq
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, _fb, params)
    first_operand = @term.operands[0]
    second_operand = @term.operands[1]
    return unless first_operand.is_a?(Symbol) && _scalar?(second_operand)
    first_operand = first_operand.to_s
    key = [maps.object_id, first_operand, @term.op]
    @idx[key] ||= { facts: {}, count: 0 }
    entry = @idx[key]
    _feed(maps.to_a, entry, first_operand)
    keys = _resolve(second_operand, params)
    matches = keys.flat_map { |k| entry[:facts][k] || [] }
    matches = matches.uniq(&:object_id) if keys.size > 1
    maps.respond_to?(:repack) ? maps.repack(matches) : matches
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
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float)
  end

  # @todo #1213:60min Notice a fact replaced in the scoped array without a change of its size.
  #  Every index, the range ones included, only compares the size of the array with the
  #  count it has seen, so it rebuilds when the array shrinks but keeps answering with the
  #  old fact when one element is swapped for another and the size stays the same.
  def _feed(facts, entry, operand)
    if entry[:count] > facts.size
      entry[:facts] = {}
      entry[:count] = 0
    end
    return unless entry[:count] < facts.size
    facts[entry[:count]..].each do |m|
      m[operand]&.uniq&.each do |v|
        entry[:facts][v] ||= []
        entry[:facts][v] << m
      end
    end
    entry[:count] = facts.size
  end

  def _resolve(operand, params)
    return [operand] unless operand.is_a?(Symbol)
    params[operand.to_s] || []
  end
end
