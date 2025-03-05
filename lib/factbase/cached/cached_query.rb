# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Query with a cache, a decorator of another query.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::CachedQuery
  # Constructor.
  # @param [Factbase::Query] origin Original query
  # @param [Hash] cache The cache
  def initialize(origin, cache)
    @origin = origin
    @cache = cache
  end

  # Iterate facts one by one.
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @yield [Fact] Facts one-by-one
  # @return [Integer] Total number of facts yielded
  def each(params = {}, &)
    raise 'Cannot cache non-abstract query' unless params.empty?
    return to_enum(__method__, params) unless block_given?
    key = "each #{@origin}"
    before = @cache[key]
    @cache[key] = @origin.each.to_a if before.nil?
    @cache[key].each(&)
  end

  # Read a single value.
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @return The value evaluated
  def one(params = {})
    raise 'Cannot cache non-abstract query' unless params.empty?
    key = "one: #{@origin}"
    before = @cache[key]
    @cache[key] = @origin.one if before.nil?
    @cache[key]
  end

  # Delete all facts that match the query.
  # @return [Integer] Total number of facts deleted
  def delete!
    @cache.clear
    @origin.delete!
  end
end
