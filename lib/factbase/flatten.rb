# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'

# Make maps suitable for printing.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Flatten
  # Constructor.
  def initialize(maps, sorter = '_id')
    @maps = maps
    @sorter = sorter
  end

  # Improve the maps.
  # @return [Array<HashMap>] The hashmaps, but improved
  def it
    @maps
      .sort_by { |m| Array(m[@sorter]).map { |v| Factbase::Flatten.key(v) } }
      .map { |m| m.sort.to_h }
      .map! { |m| m.transform_values { |v| v.size == 1 ? v[0] : v } }
  end

  # The sorting key of one value: the name of its kind, then the value
  # itself for the kinds that compare, and its text for the rest. Values
  # of different kinds never meet in a comparison this way, which is what
  # made the plain value raise (#618), while numbers stay in their own
  # order instead of the order of their digits (#695).
  # @param [Object] value The value of the sorter property
  # @return [Array] The key to sort by
  def self.key(value)
    case value
    when Numeric
      [0, value, '']
    when Time
      [1, Float(value), '']
    else
      [2, 0, value.to_s]
    end
  end
end
