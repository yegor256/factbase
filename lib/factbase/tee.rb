# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'others'
require_relative '../factbase'

# Tee of two facts.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Tee
  # Ctor.
  # @param [Factbase::Fact] fact Primary fact to use for reading
  # @param [Factbase::Fact] upper Fact to access with a "$" prefix
  def initialize(fact, upper)
    @fact = fact
    @upper = upper
  end

  def to_s
    @fact.to_s
  end

  def all_properties
    @fact.all_properties + (@upper.is_a?(Hash) ? @upper.keys : @upper.all_properties)
  end

  others do |*args|
    if args[0].to_s == '[]' && args[1].to_s.start_with?('$')
      n = args[1].to_s
      n = n[1..] unless @upper.is_a?(Factbase::Tee)
      @upper[n]
    else
      @fact.method_missing(*args)
    end
  end
end
