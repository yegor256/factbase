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

  def initialize(operands)
    @operands = operands
  end

  # Removes duplicate operands, except the ones that write into the fact,
  # such as +as+ and +join+, since each of them adds its value again, and
  # the terms made by +defn+, since their Ruby body may write too
  def unique
    strs = []
    ops = []
    @operands.each do |o|
      o = o.simplify if o.is_a?(Factbase::Term)
      s = o.to_s
      next if strs.include?(s) && !writer?(o)
      strs << s
      ops << o
    end
    ops
  end

  private

  def writer?(term)
    term.is_a?(Factbase::Term) &&
      (WRITERS.include?(term.op) || term.custom? || term.operands.any? { |operand| writer?(operand) })
  end
end
