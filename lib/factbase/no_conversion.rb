# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Prevents facts from claiming implicit Ruby conversions.
module Factbase::NoConversion
  PROTOCOLS = %i[to_ary to_str to_hash to_io to_proc to_int].freeze

  def method_missing(method, ...)
    raise(NoMethodError, "undefined method '#{method}' for #{self.class}") if PROTOCOLS.include?(method)
    super
  end

  # rubocop:disable Elegant/GoodMethodName, Style/OptionalBooleanParameter
  def respond_to?(method, include_private = false)
    return false if PROTOCOLS.include?(method)
    super
  end
  # rubocop:enable Elegant/GoodMethodName, Style/OptionalBooleanParameter

  def respond_to_missing?(method, include_private = false)
    return false if PROTOCOLS.include?(method)
    super
  end
end
