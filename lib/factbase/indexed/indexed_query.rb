# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'
require_relative 'indexed_fact'

# Query with an index, a decorator of another query.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::IndexedQuery
  include Enumerable

  # Constructor.
  # @param [Factbase::Query] origin Original query
  # @param [Hash] idx The index
  # @param [Set] fresh The set of IDs of newly inserted facts
  def initialize(origin, idx, fb, fresh)
    @origin = origin
    @idx = idx
    @fb = fb
    @fresh = fresh
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
  # @todo #1017:60min Yield the facts one by one, the way the plain query does.
  #  The facts are collected before any of them is yielded, so a caller that
  #  breaks out of the loop still pays for every remaining fact, and a term
  #  that raises on a later fact raises even though the caller never asked to
  #  see it. Streaming here breaks test_materializes_before_iterating, which
  #  relies on the snapshot to keep a nested sub-query stable while the block
  #  inserts facts, so a way to keep that guarantee without collecting first
  #  has to be found before this can change.
  def each(fb = @fb, params = {})
    return to_enum(__method__, fb, params) unless block_given?
    n = 0
    @origin.each(fb, params).to_a.tap { @fresh.clear }.each do |f|
      yield(Factbase::IndexedFact.new(f, @idx, @fresh))
      n += 1
    end
    n
  end

  # Read a single value.
  # @param [Factbase] fb The factbase
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @return [String|Integer|Float|Time|Array|NilClass] The value evaluated
  def one(fb = @fb, params = {})
    @origin.one(fb, params).tap { @fresh.clear }
  end

  # Delete all facts that match the query.
  # @param [Factbase] fb The factbase
  # @return [Integer] Total number of facts deleted
  def delete!(fb = @fb)
    @origin.delete!(fb).tap do
      @idx.clear
      @fresh.clear
    end
  end
end
