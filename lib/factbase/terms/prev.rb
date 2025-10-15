# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# The Factbase::Unique class provides functionality for evaluating the uniqueness
# of terms based on provided operands and facts.
class Factbase::Prev
  require_relative 'shared'
  include Factbase::TermShared

  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    @operands = operands
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Object] The previous value
  def evaluate(fact, maps, fb)
    assert_args(1)
    before = @prev
    v = _values(0, fact, maps, fb)
    @prev = v
    before
  end
end
