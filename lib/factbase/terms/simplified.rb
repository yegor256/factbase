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
  # such as +as+ and +join+, since each of them adds its value again
  def unique
    strs = []
    ops = []
    @operands.each do |o|
      o = o.simplify if o.is_a?(Factbase::Term)
      s = o.to_s
      next if strs.include?(s) && !(o.is_a?(Factbase::Term) && WRITERS.include?(o.op))
      strs << s
      ops << o
    end
    ops
  end
end
