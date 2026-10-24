# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'date'
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
    return Time.at(value).utc if value.is_a?(Integer) || value.is_a?(Float)
    zoned(value.to_s).tap do
      date = value.to_s.match(/\A\s*(\d{4})-(\d{2})-(\d{2})/)
      next if date.nil? || Date.valid_date?(*date.captures.map { |i| Integer(i, 10) })
      raise(ArgumentError, 'there is no such date')
    end
  rescue ArgumentError => e
    raise(RuntimeError, "Cannot parse '#{value}' as Time in (to_time ...): #{e.message}")
  end

  # Parse the text, keeping the offset of a zone that +Time.parse+ does not know.
  #
  # +Time.parse+ applies a numeric offset and a few zone names only, while
  # +Date._parse+ finds the offset of many more, like +JST+ or +UTC+03:00+.
  #
  # @param [String] text The text to parse
  # @return [Time] The time, with the offset the text says
  def zoned(text)
    t = Time.parse(text)
    off = Date._parse(text)[:offset]
    return t if off.nil? || off == t.utc_offset
    Time.new(t.year, t.month, t.day, t.hour, t.min, t.sec + t.subsec, off)
  end
end
