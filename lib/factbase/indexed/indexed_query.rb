# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Query with an index, a decorator of another query.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::IndexedQuery
  # Constructor.
  # @param [Factbase::Query] origin Original query
  # @param [Hash] idx The index
  def initialize(origin, idx)
    @origin = origin
    @idx = idx
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
  def each(params = {})
    return to_enum(__method__, params) unless block_given?
    @origin.each(params) do |f|
      yield Factbase::IndexedFact.new(f, @idx)
    end
  end

  # Read a single value.
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @return The value evaluated
  def one(params = nil)
    @origin.one(params)
  end

  # Delete all facts that match the query.
  # @return [Integer] Total number of facts deleted
  def delete!
    @idx.clear
    @origin.delete!
  end
end
