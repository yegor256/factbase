# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'exists'.
# The @idx[key] structure:
# {
#   count: Integer (number of facts already processed),
#   facts: Array (facts found),
# }
class Factbase::IndexedExists
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, _fb, _params)
    operand = @term.operands.first.to_s
    key = [maps.object_id, operand, @term.op]
    @idx[key] = { facts: [], count: 0 } if @idx[key].nil?
    entry = @idx[key]
    _feed(maps.to_a, entry, operand)
    maps.respond_to?(:repack) ? maps.repack(entry[:facts]) : entry[:facts]
  end

  private

  def _feed(facts, entry, operand)
    facts[entry[:count]..].each do |m|
      entry[:facts] << m unless m[operand].nil?
    end
    entry[:count] = facts.size
  end
end
