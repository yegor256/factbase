# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'others'
require_relative '../../factbase'

# A single fact in a factbase, which is sensitive to changes.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::CachedFact
  # Ctor.
  # @param [Factbase::Fact] origin The original fact
  # @param [Hash] cache Cache of queries (to clean it on attribute addition)
  # @param [Boolean] fresh True if this is a newly inserted fact (not yet in cache)
  def initialize(origin, cache, fresh: false)
    @origin = origin
    @cache = cache
    @fresh = fresh
  end

  def to_s
    @origin.to_s
  end

  # When a method is missing, this method is called.
  others do |*args|
    # Only clear cache when modifying properties on existing (non-fresh) facts
    # Fresh facts are not in the cache yet, so modifications don't affect it
    @cache.clear if args[0].to_s.end_with?('=') && !@fresh
    @origin.send(*args)
  end
end
