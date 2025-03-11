# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Term with an index.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::IndexedTerm < Factbase::Term
  # Ctor.
  # @param [Symbol] operator Operator
  # @param [Array] operands Operands
  # @param [Factbase] fb Optional factbase reference
  # @param [Hash] idx Index
  def initialize(operator, operands, idx: {})
    super(operator, operands)
    @idx = idx
    @cacheable = !static? && abstract?
  end

  def predict(maps)
    case @op
    when :eq
      if @operands[0].is_a?(Symbol) && _scalar?(@operands[1])
        key = [maps.object_id, @operands[0], @op]
        if @idx[key].nil?
          @idx[key] = {}
          maps.to_a.each do |m|
            m[@operands[0].to_s]&.each do |v|
              @idx[key][v] = [] if @idx[key][v].nil?
              @idx[key][v].append(m)
            end
          end
        end
        @idx[key][@operands[1]] || []
      else
        maps.to_a
      end
    when :and
      parts = @operands.map { |o| o.predict(maps) }
      if parts.include?(nil)
        maps
      else
        parts.reduce(&:&)
      end
    when :or
      @operands.map { |o| o.predict(maps) }.reduce(&:|)
    when :join
    when :as
      nil
    else
      maps.to_a
    end
  end

  private

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float)
  end
end
