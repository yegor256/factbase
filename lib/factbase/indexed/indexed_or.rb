# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'or'.
class Factbase::IndexedOr
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, fb, params, _context = [], _tail = [])
    return nil if @idx.nil?
    r = nil
    @term.operands.each do |o|
      n = o.predict(maps, fb, params)
      if n.nil?
        r = nil
        break
      end
      r = maps & [] if r.nil?
      r |= n.to_a
      return maps if r.size > maps.size / 4 # it's big enough already
    end
    r
  end
end
