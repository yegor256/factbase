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

  others do |*args|
    @idx.clear if args[0].to_s.end_with?('=') && !@fresh.include?(object_id)
    @origin.__send__(*args)
  end
end
