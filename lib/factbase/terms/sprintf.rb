# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# Format term.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Sprintf < Factbase::TermBase
  def initialize(operands)
    super()
    @operands = operands
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [String] The formatted string
  def evaluate(fact, maps, fb)
    fmt = _values(0, fact, maps, fb)[0]
    ops = (1..(@operands.length - 1)).map { |i| _values(i, fact, maps, fb)&.first }
    format(*([fmt] + ops))
  end
end
