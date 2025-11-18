# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'one'.
class Factbase::IndexedOne
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, _fb, _params)
    return nil if @idx.nil?
    key = [maps.object_id, @term.operands.first, @term.op]
    if @idx[key].nil?
      yes = @operands.first.predict(maps, fb, params)
      if yes.nil?
        @idx[key] = { r: nil }
      else
        yes = yes.to_a.to_set
        @idx[key] = { r: maps.to_a.reject { |m| yes.include?(m) } }
      end
    end
    r = @idx[key][:r]
    if r.nil?
      nil
    else
      (maps & []) | r
    end
  end
end
