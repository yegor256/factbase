# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# The term 'always' that always evaluates to true.
# If you want to return all the facts you might use '(always)' query.
class Factbase::Always < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands = [])
    super()
    @operands = operands
    @op = :always
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] _fact The fact
  # @param [Array<Factbase::Fact>] _maps All maps available
  # @param [Factbase] _fb Factbase to use for sub-queries
  # @return [Boolean] Always returns true
  def evaluate(_fact, _maps, _fb)
    assert_args(0)
    true
  end
end
