# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'

# Predicted live maps with query-local computed properties kept separately.
# The maps retain their identity and transaction decorators. Extras belong to
# this prediction only and are copied before another evaluation can append to them.
class Factbase::Prediction < Array
  def initialize(maps, extras)
    super(maps)
    @extras = extras
  end

  # Computed values for a map, without changing its persistent properties.
  # @param [Hash] map A predicted map
  # @return [Hash] Independent arrays of computed values
  def extras(map)
    @extras.fetch(map, {}).transform_values(&:dup)
  end
end
