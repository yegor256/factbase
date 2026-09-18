# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'date'
require 'time'
require_relative 'base'
# Represents a string conversion term 'to_time'.
# This class is used to evaluate a term and return its time representation.
class Factbase::ToTime < Factbase::TermBase
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
  # @return [Time] Time representation of the value
  def evaluate(fact, maps, fb)
    assert_args(1)
    vv = _values(0, fact, maps, fb)
    return if vv.nil?
    parse(vv[0])
  end

  private

  def parse(value)
    return value if value.is_a?(Time)
    Time.parse(dated(value.to_s))
  rescue ArgumentError => e
    raise(RuntimeError, "Cannot parse '#{value}' as Time in (to_time ...): #{e.message}")
  end

  # The text, if it carries a date.
  #
  # +Time.parse+ takes whatever the text does not say from the clock, so a
  # text that holds a time of day and no date means a different moment every
  # day. A text that says nothing at all is left to +Time.parse+ to refuse.
  #
  # @param [String] text The text to read
  # @return [String] The same text
  def dated(text)
    parts = Date._parse(text)
    return text if parts.empty?
    return text if parts[:year] && parts[:mon] && parts[:mday]
    raise(
      RuntimeError,
      "Cannot parse '#{text}' as Time in (to_time ...): it carries no date, and the date " \
      'would come from the clock, which would answer a different time every day'
    )
  end
end
