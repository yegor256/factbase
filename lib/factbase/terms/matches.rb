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
  # @return [Boolean] True if the string matches the regexp, false otherwise
  def evaluate(fact, maps, fb)
    assert_args(2)
    str = _values(0, fact, maps, fb)
    return false if str.nil?
    raise(RuntimeError, 'Exactly one string is expected') unless str.size == 1
    re = _values(1, fact, maps, fb)
    raise(RuntimeError, 'Regexp is nil') if re.nil?
    raise(RuntimeError, 'Exactly one regexp is expected') unless re.size == 1
    str[0].to_s.match?(regexp(re[0]))
  end

  private

  def regexp(pattern)
    key = pattern.to_s
    @regexps[key] ||= Regexp.new(key)
  rescue RegexpError => e
    raise(RuntimeError, "Invalid regexp '#{key}': #{e.message}")
  end
end
