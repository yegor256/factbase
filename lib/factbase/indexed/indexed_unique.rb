# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'unique'.
class Factbase::IndexedUnique
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, _fb, _params)
    return nil if @idx.nil?
    key = [maps.object_id, @term.operands.first, @term.op]
    if @idx[key].nil?
      props = @term.operands.map(&:to_s)
      @idx[key] = maps.to_a.select { |m| props.all? { |p| !m[p].nil? } }
    end
    (maps & []) | @idx[key]
  end
end
