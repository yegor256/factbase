# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'eq'.
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

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end

  def _feed(facts, entry, operand)
    return unless entry[:count] < facts.size
    facts[entry[:count]..].each do |m|
      m[operand]&.each do |v|
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
