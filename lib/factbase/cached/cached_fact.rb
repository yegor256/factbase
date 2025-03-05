# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'others'
require_relative '../../factbase'

# A single fact in a factbase, which is sentitive to changes.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::CachedFact
  # Ctor.
  # @param [Factbase::Fact] origin The original fact
  # @param [Hash] cache Cache of queries (to clean it on attribute addition)
  def initialize(origin, cache)
    @origin = origin
    @cache = cache
  end

  # When a method is missing, this method is called.
  others do |*args|
    @cache.clear if args[0].to_s.end_with?('=')
    @origin.send(*args)
  end
end
