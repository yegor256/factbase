# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Test for unique term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT

# Base class for all terms.
class Factbase::TermBase
  # Turns it into a string.
  # @return [String] The string of it
  def to_s
    @to_s ||=
      begin
        items = []
        items << @op
        items +=
          @operands.map do |o|
            if o.is_a?(String)
              "'#{o.gsub("'", "\\\\'").gsub('"', '\\\\"')}'"
            elsif o.is_a?(Time)
              o.utc.iso8601
            else
              o.to_s
            end
          end
        "(#{items.join(' ')})"
      end
  end

  private

  def assert_args(num)
    c = @operands.size
    raise "Too many (#{c}) operands for '#{@op}' (#{num} expected)" if c > num
    raise "Too few (#{c}) operands for '#{@op}' (#{num} expected)" if c < num
  end

  def _by_symbol(pos, fact)
    o = @operands[pos]
    raise "A symbol expected at ##{pos}, but '#{o}' (#{o.class}) provided" unless o.is_a?(Symbol)
    k = o.to_s
    fact[k]
  end

  # @return [Array|nil] Either array of values or NIL
  def _values(pos, fact, maps, fb)
    v = @operands[pos]
    v = v.evaluate(fact, maps, fb) if v.is_a?(Factbase::Term)
    v = v.evaluate(fact, maps, fb) if v.is_a?(Factbase::TermBase)
    v = fact[v.to_s] if v.is_a?(Symbol)
    return v if v.nil?
    unless v.is_a?(Array)
      v =
        if v.respond_to?(:each)
          v.to_a
        else
          [v]
        end
    end
    raise 'Why not array?' unless v.is_a?(Array)
    unless v.all? { |i| [Float, Integer, String, Time, TrueClass, FalseClass].any? { |t| i.is_a?(t) } }
      raise 'Wrong type inside'
    end
    v
  end
end
