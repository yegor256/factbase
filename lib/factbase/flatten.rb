# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'

# Make maps suitable for printing.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
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
      .sort_by { |m| m[@sorter] || [] }
      .map { |m| m.sort.to_h }
      .map { |m| m.transform_values { |v| v.size == 1 ? v[0] : v } }
  end
end
