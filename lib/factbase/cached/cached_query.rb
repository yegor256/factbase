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
  def each(fb = @fb, params = nil)
    return to_enum(__method__, fb, params) unless block_given?
    key = "each #{@origin}"
    before = @cache[key]
    @cache[key] = @origin.each(fb).to_a if before.nil?
    @cache[key].each do |f|
      require_relative 'cached_fact'
      yield Factbase::CachedFact.new(f, @cache)
    end
  end

  # Read a single value.
  # @param [Hash] fb The factbase
  # @param [Hash] _params Optional params accessible in the query via the "$" symbol (unused)
  # @return The value evaluated
  def one(fb = @fb, _params = nil)
    key = "one: #{@origin}"
    before = @cache[key]
    @cache[key] = @origin.one(fb) if before.nil?
    @cache[key]
  end

  # Delete all facts that match the query.
  # @return [Integer] Total number of facts deleted
  def delete!(fb = @fb)
    @cache.clear
    @origin.delete!(fb)
  end
end
