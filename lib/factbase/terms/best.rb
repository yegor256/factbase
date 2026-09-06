# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# The 'best' term evaluates the best value for a given key.
class Factbase::Best
  def initialize(&block)
    @criteria = block
  end

  def evaluate(key, maps)
    raise(ArgumentError, "A symbol is expected, but #{key} provided") unless key.is_a?(Symbol)
    best = nil
    maps.each do |m|
      vv = m[key.to_s]
      next if vv.nil?
      vv = [vv] unless vv.respond_to?(:to_a)
      vv.each do |v|
        if best.nil?
          best = v
          next
        end
        begin
          best = v if @criteria.call(v, best)
        rescue ArgumentError, TypeError
          raise(
            ArgumentError,
            "Can't compare '#{v}' (#{v.class}) with '#{best}' (#{best.class}) in the '#{key}' property"
          )
        end
      end
    end
    best
  end
end
