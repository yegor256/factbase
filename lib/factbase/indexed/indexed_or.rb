# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'or'.
class Factbase::IndexedOr
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  # Merge by identity: hashing fact maps (Time included) costs more than the merge.
  def predict(maps, fb, params)
    return if @idx.nil?
    r = nil
    seen = {}.compare_by_identity
    failed = false
    @term.operands.each do |o|
      n = o.predict(maps, fb, params)
      if n.nil?
        failed = true
        break
      end
      r ||= []
      n.to_a.each do |m|
        next if seen.key?(m)
        seen[m] = true
        r << m
      end
      return maps if r.size > maps.size / 4
    end
    return if failed || r.nil?
    maps.respond_to?(:repack) ? maps.repack(r) : r
  end
end
