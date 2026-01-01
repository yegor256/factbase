# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'
require_relative 'cached_fact'

# Query with a cache, a decorator of another query.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::CachedQuery
  include Enumerable

  # Constructor.
  # @param [Factbase::Query] origin Original query
  # @param [Hash] cache The cache
  def initialize(origin, cache, fb)
    @origin = origin
    @cache = cache
    @fb = fb
  end

  # Print it as a string.
  # @return [String] The query as a string
  def to_s
    @origin.to_s
  end

  # Iterate facts one by one.
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @yield [Fact] Facts one-by-one
  # @return [Integer] Total number of facts yielded
  def each(fb = @fb, params = {})
    return to_enum(__method__, fb, params) unless block_given?
    invalidate_if_dirty!
    key = "each #{@origin}" # params are ignored!
    before = @cache[key]
    @cache[key] = @origin.each(fb, params).to_a if before.nil?
    c = 0
    @cache[key].each do |f|
      c += 1
      yield Factbase::CachedFact.new(f, @cache)
    end
    c
  end

  # Read a single value.
  # @param [Hash] fb The factbase
  # @param [Hash] params Optional params accessible in the query via the "$" symbol (unused)
  # @return The value evaluated
  def one(fb = @fb, params = {})
    invalidate_if_dirty!
    key = "one: #{@origin} #{params}"
    before = @cache[key]
    @cache[key] = @origin.one(fb, params) if before.nil?
    @cache[key]
  end

  # Delete all facts that match the query.
  # @return [Integer] Total number of facts deleted
  def delete!(fb = @fb)
    @cache.clear
    @origin.delete!(fb)
  end

  private

  # Clear cache if it was marked dirty by a fresh fact insertion.
  # This implements lazy invalidation: we don't clear on every insert,
  # only when a query actually runs after inserts happened.
  def invalidate_if_dirty!
    return unless @cache.delete(:__dirty__)
    @cache.clear
  end
end
