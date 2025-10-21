# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# Factbase::Defn is responsible for defining new terms in the Factbase system.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Defn < Factbase::TermBase
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
  # @return [Object] Term definition result
  def evaluate(_fact, _maps, _fb)
    assert_args(2)
    fn = @operands[0]
    raise "A symbol expected as first argument of 'defn'" unless fn.is_a?(Symbol)
    raise "Can't use '#{fn}' name as a term" if Factbase::Term.instance_methods(true).include?(fn)
    raise "Term '#{fn}' is already defined" if Factbase::Term.private_instance_methods(false).include?(fn)
    raise "The '#{fn}' is a bad name for a term" unless fn.match?(/^[a-z_]+$/)
    e = "class Factbase::Term\nprivate\ndef #{fn}(fact, maps, fb)\n#{@operands[1]}\nend\nend"
    # rubocop:disable Security/Eval
    eval(e)
    # rubocop:enable Security/Eval
    true
  end
end
