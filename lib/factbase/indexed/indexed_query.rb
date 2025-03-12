# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'
require_relative 'indexed_fact'

# Query with an index, a decorator of another query.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::IndexedQuery
  # Constructor.
  # @param [Factbase::Query] origin Original query
  # @param [Hash] idx The index
  def initialize(origin, idx, fb)
    @origin = origin
    @idx = idx
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
    @origin.each(fb, params) do |f|
      yield Factbase::IndexedFact.new(f, @idx)
    end
  end

  # Read a single value.
  # @param [Factbase] fb The factbase
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @return [String|Integer|Float|Time|Array|NilClass] The value evaluated
  def one(fb = @fb, params = nil)
    @origin.one(fb, params)
  end

  # Delete all facts that match the query.
  # @param [Factbase] fb The factbase
  # @return [Integer] Total number of facts deleted
  def delete!(fb = @fb)
    @idx.clear
    @origin.delete!(fb)
  end
end
