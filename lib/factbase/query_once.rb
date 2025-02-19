# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'

# Query with a cache, a decorator of another query.
#
# It is NOT thread-safe!
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::QueryOnce
  # Constructor.
  # @param [Factbase] fb Factbase
  # @param [Factbase::Query] query Original query
  # @param [Array<Hash>] maps Where to search
  def initialize(fb, query, maps)
    @fb = fb
    @query = query
    @maps = maps
  end

  # Iterate facts one by one.
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @yield [Fact] Facts one-by-one
  # @return [Integer] Total number of facts yielded
  def each(params = {}, &)
    unless block_given?
      return to_enum(__method__, params) if Factbase::Syntax.new(@fb, @query).to_term.abstract?
      key = [@query.to_s, @maps.object_id]
      before = @fb.cache[key]
      @fb.cache[key] = to_enum(__method__, params).to_a if before.nil?
      return @fb.cache[key]
    end
    @query.each(params, &)
  end

  # Read a single value.
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @return The value evaluated
  def one(params = {})
    @query.one(params)
  end

  # Delete all facts that match the query.
  # @return [Integer] Total number of facts deleted
  def delete!
    @fb.cache.clear
    @query.delete!
  end
end
