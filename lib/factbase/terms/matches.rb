# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'

# Matches term.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Matches < Factbase::TermBase
  def initialize(operands)
    super()
    @operands = operands
    @regexps = {}
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] True if any value matches the regexp, false otherwise
  def evaluate(fact, maps, fb)
    assert_args(2)
    str = _values(0, fact, maps, fb)
    return false if str.nil?
    re = _values(1, fact, maps, fb)
    raise(RuntimeError, 'Regexp is nil') if re.nil?
    raise(RuntimeError, 'Exactly one regexp is expected') unless re.size == 1
    rx = regexp(re[0])
    str.any? { |s| s.to_s.match?(rx) }
  end

  private

  def regexp(pattern)
    key = pattern.to_s
    @regexps[key] ||= Regexp.new(key)
  rescue RegexpError => e
    raise(RuntimeError, "Invalid regexp '#{key}': #{e.message}")
  end
end
