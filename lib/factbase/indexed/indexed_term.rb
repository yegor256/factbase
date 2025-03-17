# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

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
  def predict(maps, params)
    case @op
    when :exists
      key = [maps.object_id, @operands[0], @op]
      if @idx[key].nil?
        @idx[key] = []
        prop = @operands[0].to_s
        maps.to_a.each do |m|
          @idx[key].append(m) unless m[prop].nil?
        end
      end
      (maps & []) | @idx[key]
    when :eq
      if @operands[0].is_a?(Symbol) && _scalar?(@operands[1])
        key = [maps.object_id, @operands[0], @op]
        if @idx[key].nil?
          @idx[key] = {}
          prop = @operands[0].to_s
          maps.to_a.each do |m|
            m[prop]&.each do |v|
              @idx[key][v] = [] if @idx[key][v].nil?
              @idx[key][v].append(m)
            end
          end
        end
        vv =
          if @operands[1].is_a?(Symbol)
            sym = @operands[1].to_s.gsub(/^\$/, '')
            params[sym] || []
          else
            [@operands[1]]
          end
        if vv.empty?
          nil
        else
          j = vv.map { |v| @idx[key][v] || [] }.reduce(&:|)
          (maps & []) | j
        end
      else
        maps
      end
    when :and
      parts = @operands.map { |o| o.predict(maps, params) }
      if parts.include?(nil)
        maps
      else
        parts.reduce(&:&)
      end
    when :or
      @operands.map { |o| o.predict(maps, params) }.reduce(maps & [], &:|)
    when :join, :as
      nil
    else
      maps
    end
  end

  private

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end
end
