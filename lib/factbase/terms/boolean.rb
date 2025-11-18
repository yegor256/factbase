# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# Boolean value checker.
class Factbase::Boolean
  # Constructor.
  # @param [Object] val The value to check
  # @param [Object] from The source of the value (for error messages)
  # @return [Boolean] The boolean value
  # @raise [RuntimeError] If value is not a boolean
  def initialize(val, from)
    @val = val
    @from = from
  end

  # @return [Boolean] The boolean value
  # @raise [RuntimeError] If value is not a boolean
  def bool?
    val = @val
    val = val[0] if val.respond_to?(:each)
    return false if val.nil?
    return val if val.is_a?(TrueClass) || val.is_a?(FalseClass)
    raise "Boolean is expected, while #{val.class} received from #{@from}"
  end
end
