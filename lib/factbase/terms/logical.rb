# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Logical terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Logical
  # Simplifies AND or OR expressions by removing duplicates
  # @return [Factbase::Term] Simplified term
  def and_or_simplify
    strs = []
    ops = []
    @operands.each do |o|
      o = o.simplify
      s = o.to_s
      next if strs.include?(s)
      strs << s
      ops << o
    end
    return ops[0] if ops.size == 1
    self.class.new(@op, ops)
  end

  # Simplifies AND expressions by removing duplicates
  # @return [Factbase::Term] Simplified term
  def and_simplify
    and_or_simplify
  end

  # Simplifies OR expressions by removing duplicates
  # @return [Factbase::Term] Simplified term
  def or_simplify
    and_or_simplify
  end
end
