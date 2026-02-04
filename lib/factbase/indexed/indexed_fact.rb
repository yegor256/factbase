# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'others'
require_relative '../../factbase'

# A single fact in a factbase, which is sensitive to changes.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::IndexedFact
  # Ctor.
  # @param [Factbase::Fact] origin The original fact
  # @param [Hash] idx The index
  # @param [Set] fresh The shared set of fresh fact IDs
  def initialize(origin, idx, fresh)
    @origin = origin
    @idx = idx
    @fresh = fresh
  end

  def to_s
    @origin.to_s
  end

  # When a method is missing, this method is called.
  others do |*args|
    # Only clear index when modifying properties on existing (non-fresh) facts
    # Fresh facts are not in the index yet, so modifications don't affect it
    @idx.clear if args[0].to_s.end_with?('=') && !@fresh.include?(object_id)
    @origin.send(*args)
  end
end
