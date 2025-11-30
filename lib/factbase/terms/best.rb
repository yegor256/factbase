# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# The 'best' term evaluates the best value for a given key.
class Factbase::Best
  def initialize(&block)
    @criteria = block
  end

  def evaluate(key, maps)
    raise "A symbol is expected, but #{key} provided" unless key.is_a?(Symbol)
    best = nil
    maps.each do |m|
      vv = m[key.to_s]
      next if vv.nil?
      vv = [vv] unless vv.respond_to?(:to_a)
      vv.each do |v|
        best = v if best.nil? || @criteria.call(v, best)
      end
    end
    best
  end
end
