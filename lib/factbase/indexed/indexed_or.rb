# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'or'.
class Factbase::IndexedOr
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, fb, params)
    return if @idx.nil?
    ids = nil
    @term.operands.each do |o|
      n = o.predict(maps, fb, params)
      if n.nil?
        ids = nil
        break
      end
      ids = Set.new if ids.nil?
      n.to_a.each { |m| ids << m.object_id }
      return maps if ids.size > maps.size / 4
    end
    return if ids.nil?
    _ordered(maps, ids)
  end

  private

  # The facts the operands have hit, in the order the factbase holds them.
  #
  # The operands are walked one by one, so their hits come out grouped by
  # operand. A query answers in insertion order, whichever operand matched.
  #
  # @param [Array<Hash>] maps All the facts
  # @param [Set<Integer>] ids The identities of the facts that were hit
  # @return [Array<Hash>] The facts, in insertion order
  def _ordered(maps, ids)
    r = maps.to_a.select { |m| ids.include?(m.object_id) }
    maps.respond_to?(:repack) ? maps.repack(r) : r
  end
end
