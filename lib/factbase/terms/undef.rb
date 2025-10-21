# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# Implements the `undef` term for Factbase, which removes a method from the class.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Undef < Factbase::TermBase
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
  # @return [Boolean] True if definition is successfully removed.
  def evaluate(_fact, _maps, _fb)
    assert_args(1)
    fn = @operands[0]
    raise "A symbol expected as first argument of 'undef'" unless fn.is_a?(Symbol)
    if Factbase::Term.private_instance_methods(false).include?(fn)
      Factbase::Term.class_eval("undef :#{fn}", __FILE__, __LINE__ - 1) # undef :foo
    end
    true
  end
end
