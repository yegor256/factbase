# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Synchronized thread-safe query.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::SyncQuery
  # Constructor.
  # @param [Factbase::Query] origin Original query
  # @param [Mutex] mutex The mutex
  def initialize(origin, mutex, fb)
    @origin = origin
    @mutex = mutex
    @fb = fb
  end

  # Turn it to a string.
  def to_s
    @origin.to_s
  end

  # Iterate facts one by one.
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @yield [Fact] Facts one-by-one
  # @return [Integer] Total number of facts yielded
  def each(fb = @fb, params = {}, &)
    return to_enum(__method__, fb, params) unless block_given?
    try_lock do
      @origin.each(fb, params, &)
    end
  end

  # Read a single value.
  # @param [Factbase] fb The factbase
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @return [String|Integer|Float|Time|Array|NilClass] The value evaluated
  def one(fb = @fb, params = {})
    try_lock do
      @origin.one(fb, params)
    end
  end

  # Delete all facts that match the query.
  # @param [Factbase] fb The factbase
  # @return [Integer] Total number of facts deleted
  def delete!(fb = @fb)
    try_lock do
      @origin.delete!(fb)
    end
  end

  private

  def try_lock
    locked = @mutex.try_lock
    r = yield
    @mutex.unlock if locked
    r
  end
end
