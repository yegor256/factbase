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
    @idx[key] ||= { facts: {}, count: 0, pos: {} }
    entry = @idx[key]
    _feed(maps.to_a, entry, first_operand)
    keys = _resolve(second_operand, params)
    matches = keys.flat_map { |k| entry[:facts][k] || [] }
    matches = _ordered(entry, matches) if keys.size > 1
    maps.respond_to?(:repack) ? maps.repack(matches) : matches
  end

  private

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end

  # The facts, in the order the factbase holds them.
  #
  # A parameter with several values is walked value by value, so the hits
  # come out grouped by value. A query answers in insertion order, whichever
  # value matched.
  #
  # @param [Hash] entry The index entry, with the position of every fact in it
  # @param [Array<Hash>] matches The facts that were hit, in any order
  # @return [Array<Hash>] The same facts, in insertion order
  def _ordered(entry, matches)
    matches.uniq(&:object_id).sort_by { |m| entry[:pos][m.object_id] }
  end

  def _feed(facts, entry, operand)
    return unless entry[:count] < facts.size
    facts[entry[:count]..].each_with_index do |m, i|
      entry[:pos][m.object_id] = entry[:count] + i
      m[operand]&.uniq&.each do |v|
        entry[:facts][v] ||= []
        entry[:facts][v] << m
      end
    end
    entry[:count] = facts.size
  end

  def _resolve(operand, params)
    return Array(operand) unless operand.is_a?(Symbol)
    params[operand.to_s] || []
  end
end
