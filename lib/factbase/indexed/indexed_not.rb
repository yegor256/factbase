# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'not'.
class Factbase::IndexedNot
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, fb, params)
    sub = @term.operands.first
    key = [maps.object_id, sub, @term.op]
    @idx[key] ||= { facts: nil, count: 0, yes_set: nil }
    entry = @idx[key]
    _feed(maps.to_a, entry) do
      sub.predict(maps, fb, params)
    end
    return nil if entry[:facts].nil?
    maps.respond_to?(:repack) ? maps.repack(entry[:facts]) : entry[:facts]
  end

  private

  def _feed(facts, entry)
    return unless entry[:count] < facts.size
    yes = yield
    if yes.nil?
      entry[:facts] = nil
      entry[:yes_set] = nil
    else
      yes_set = yes.to_a.to_set
      entry[:yes_set] = yes_set
      entry[:facts] = facts.reject { |m| yes_set.include?(m) }
    end
    entry[:count] = facts.size
  end
end
