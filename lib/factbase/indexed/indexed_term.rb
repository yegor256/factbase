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

  def cmp(op, fact, maps)
    assert_args(2)
    lefts = the_values(0, fact, maps)
    return false if lefts.nil?
    rights = the_values(1, fact, maps)
    return false if rights.nil?
    lefts.any? do |l|
      l = l.floor if l.is_a?(Time) && op == :==
      rights.any? do |r|
        r = r.floor if r.is_a?(Time) && op == :==
        l.send(op, r)
      end
    end
  end
end
