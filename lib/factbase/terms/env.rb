# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# The `Factbase::Env` class is used to evaluate terms based on environment variables.
# It retrieves the value of an environment variable or returns a default value if the variable is not set.
class Factbase::Env < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [String] The value of the environment variable or the default
  def evaluate(fact, maps, fb)
    assert_args(2)
    n = _values(0, fact, maps, fb)[0]
    ENV.fetch(n.upcase) { _values(1, fact, maps, fb)[0] }
  end
end
