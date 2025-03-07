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
  def initialize(operator, operands, fb: nil, idx: {})
    super(operator, operands, fb: fb)
    @idx = idx
    @cacheable = !static? && abstract?
  end

  def predict(maps)
    case @op
    when :eq
      if @operands[0].is_a?(Symbol) && !@operands[1].is_a?(Array)
        key = [maps.object_id, @operands[0], @operator]
        if @idx[key].nil?
          @idx[key] = maps.group_by { |m| m[@operands[0]] }
        end
        @idx[key][@operands[1]] || []
      else
        maps
      end
    when :and
      @operands.map { |o| o.predict(maps) }.reduce(&:&)
    when :or
      @operands.map { |o| o.predict(maps) }.reduce(&:|)
    else
      maps
    end
  end
end
