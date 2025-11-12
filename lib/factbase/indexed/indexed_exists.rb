# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'exists'.
class Factbase::IndexedExists
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, _fb, _params)
    return nil if @idx.nil?
    key = [maps.object_id, @term.operands.first, @term.op]
    if @idx[key].nil?
      @idx[key] = []
      prop = @term.operands.first.to_s
      maps.to_a.each do |m|
        @idx[key].append(m) unless m[prop].nil?
      end
    end
    (maps & []) | @idx[key]
  end
end
