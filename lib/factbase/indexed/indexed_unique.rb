# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'unique'.
# The @idx[ikey] structure:
# {
#   count: Integer (number of facts already processed),
#   buckets: {
#     key => {
#       facts: Array (unique facts found),
#       seen: Set (composite values already indexed to skip duplicates)
#     }
#   }
# }
# Example 1: (unique "fruit")
#   - Apple, Apple, Banana
#   - count: 3, facts: [Apple, Banana], seen: { [Apple], [Banana] }
#
# Example 2: (unique "fruit" "color")
#   - [Apple, Red], [Apple, Green], [Apple, Red]
#   - count: 3, facts: [[Apple, Red], [Apple, Green]], seen: { [Apple, Red], [Apple, Green] }
class Factbase::IndexedUnique
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, _fb, params, context, tail)
    operands = _resolve_operands(params)
    bucket_key = operands.join('|')
    idx_key = [maps.object_id, @term.op.to_s, bucket_key, context]
    entry = (@idx[idx_key] ||= { buckets: {}, count: 0 })
    source = context.empty? ? maps : tail
    _feed(source.to_a, entry, operands, bucket_key)
    matches = entry[:buckets][bucket_key][:facts]
    maps.respond_to?(:repack) ? maps.repack(matches) : matches
  end

  private

  def _feed(facts, entry, operands, bucket_key)
    entry[:buckets][bucket_key] ||= { facts: [], seen: Set.new }
    bucket = entry[:buckets][bucket_key]
    (facts[entry[:count]..] || []).each do |fact|
      composite_val = operands.map { |o| fact[o] }
      next if composite_val.any?(&:nil?)
      bucket[:facts] << fact if bucket[:seen].add?(composite_val)
    end
    entry[:count] = facts.size
  end

  def _resolve_operands(params)
    @term.operands.map do |op|
      params.respond_to?(:resolve) ? params.resolve(op) : [op]
    end.flatten.map(&:to_s)
  end
end
