# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
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

  # @return [Boolean] TRUE if at least one of the values is TRUE
  # @raise [RuntimeError] If value is not a boolean
  def bool?
    bools.any?
  end

  # @return [Boolean] TRUE if all values are TRUE and there is at least one
  # @raise [RuntimeError] If value is not a boolean
  def every?
    list = bools
    !list.empty? && list.all?
  end

  private

  def bools
    list = @val.respond_to?(:each) ? @val.to_a : [@val]
    list.each_with_object([]) do |v, acc|
      next if v.nil?
      unless v.is_a?(TrueClass) || v.is_a?(FalseClass)
        raise(ArgumentError, "Boolean is expected, while #{v.class} received from #{@from}")
      end
      acc << v
    end
  end
end
