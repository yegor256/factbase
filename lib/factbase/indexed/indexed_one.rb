# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'one'.
class Factbase::IndexedOne
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, _fb, _params)
    prop = @term.operands.first.to_s
    key = [maps.object_id, prop, @term.op]
    @idx[key] ||= { facts: [], count: 0 }
    entry = @idx[key]
    _feed(maps.to_a, entry, prop)
    maps.respond_to?(:repack) ? maps.repack(entry[:facts]) : entry[:facts]
  end

  private

  def _feed(facts, entry, prop)
    return unless entry[:count] < facts.size
    facts[entry[:count]..].each do |f|
      entry[:facts] << f if !f[prop].nil? && f[prop].size == 1
    end
    entry[:count] = facts.size
  end
end
