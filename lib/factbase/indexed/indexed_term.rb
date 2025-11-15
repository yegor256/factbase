# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'tago'
require_relative '../../factbase'
require_relative '../indexed/indexed_eq'
require_relative '../indexed/indexed_lt'
require_relative '../indexed/indexed_gt'
require_relative '../indexed/indexed_one'
require_relative '../indexed/indexed_exists'
require_relative '../indexed/indexed_and'
require_relative '../indexed/indexed_absent'
require_relative '../indexed/indexed_unique'

# Term with an index.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::IndexedTerm
  # Reduces the provided list of facts (maps) to a smaller array, if it's possible.
  #
  # NIL must be returned if indexing is prohibited in this case.
  #
  # @param [Array<Hash>] maps Array of facts
  # @param [Hash] params Key/value params to use
  # @return [Array<Hash>|nil] Returns a new array, or NIL if the original array must be used
  def predict(maps, fb, params)
    if @terms.key?(@op)
      t = @terms[@op]
      return t.predict(maps, fb, params) if t.respond_to?(:predict)
    end
    m = :"#{@op}_predict"
    return send(m, maps, fb, params) if respond_to?(m)
    _init_indexes until @indexes
    if @indexes.key?(@op)
      index = @indexes[@op]
      return index.predict(maps, fb, params)
    end
    key = [maps.object_id, @operands.first, @op]
    case @op
    when :or
      r = nil
      @operands.each do |o|
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
    when :not
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

  private

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end

  def _init_indexes
    @indexes = {
      eq: Factbase::IndexedEq.new(self, @idx),
      lt: Factbase::IndexedLt.new(self, @idx),
      gt: Factbase::IndexedGt.new(self, @idx),
      one: Factbase::IndexedOne.new(self, @idx),
      exists: Factbase::IndexedExists.new(self, @idx),
      absent: Factbase::IndexedAbsent.new(self, @idx),
      unique: Factbase::IndexedUnique.new(self, @idx),
      and: Factbase::IndexedAnd.new(self, @idx)
    }
  end
end
