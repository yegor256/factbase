# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'unique'.
# @todo #249:30min Improve prediction for 'unique' term. Current prediction is quite naive and
#  returns many false positives because it just filters facts which have exactly the same set
#  of keys regardless the values. We should introduce more smart prediction.
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
