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
    matches = keys.flat_map { |k| entry[:facts][_key(k)] || [] }
    matches = matches.uniq(&:object_id) if keys.size > 1
    maps.respond_to?(:repack) ? maps.repack(matches) : matches
  end

  private

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end

  # The key a value is indexed by.
  #
  # A Hash tells its keys apart with +eql?+, which says that 1 and 1.0 are
  # two different keys, while the plain +eq+ term compares with +==+, which
  # says they are the same. A number is therefore kept as an exact Rational,
  # so that both of them land on one key.
  #
  # @param [Object] value The value, as a fact holds it
  # @return [Object] The key to put it in the index under
  def _key(value)
    return value unless value.is_a?(Integer) || value.is_a?(Float)
    return value if value.is_a?(Float) && !value.finite?
    Rational(value)
  end

  def _feed(facts, entry, operand)
    return unless entry[:count] < facts.size
    facts[entry[:count]..].each do |m|
      m[operand]&.uniq&.each do |v|
        k = _key(v)
        entry[:facts][k] ||= []
        entry[:facts][k] << m
      end
    end
    entry[:count] = facts.size
  end

  def _resolve(operand, params)
    return Array(operand) unless operand.is_a?(Symbol)
    params[operand.to_s] || []
  end
end
