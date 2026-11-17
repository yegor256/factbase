# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Simplified operands.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Simplified
  WRITERS = %i[as join].freeze
  STATEFUL = %i[prev traced unique].freeze

  def initialize(operands)
    @operands = operands
  end

  # Removes duplicate operands, except the ones that write into the fact,
  # such as +as+ and +join+, since each of them adds its value again,
  # and the ones with a stateful term, such as +unique+, anywhere inside,
  # since each copy of such a term remembers its own facts
  def unique
    strs = []
    ops = []
    @operands.each do |o|
      o = o.simplify if o.is_a?(Factbase::Term)
      s = o.to_s
      next if strs.include?(s) && !kept?(o)
      strs << s
      ops << o
    end
    ops
  end

  private

  def kept?(term)
    term.is_a?(Factbase::Term) &&
      (WRITERS.include?(term.op) || STATEFUL.include?(term.op) || term.operands.any? { |operand| kept?(operand) })
  end
end
