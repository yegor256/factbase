# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require_relative '../../factbase'

# A synchronous thread-safe factbase.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::SyncFactbase
  decoor(:origin)

  # Constructor.
  # @param [Factbase] origin Original factbase to decorate
  # @param [Mutex] mutex Mutex to use for synchronization
  def initialize(origin, mutex = Mutex.new)
    @origin = origin
    @mutex = mutex
  end

  # Insert a new fact and return it.
  # @return [Factbase::Fact] The fact just inserted
  def insert
    @mutex.synchronize do
      @origin.insert
    end
  end

  # Create a query capable of iterating.
  # @param [String] term The query to use for selections
  # @param [Array<Hash>] maps Possible maps to use
  def query(term, maps = nil)
    term = Factbase::Syntax.new(term).to_term(@origin) if term.is_a?(String)
    @mutex.synchronize do
      require_relative 'sync_query'
      Factbase::SyncQuery.new(@origin.query(term, maps), @mutex)
    end
  end

  # Run an ACID transaction.
  # @return [Factbase::Churn] How many facts have been changed (zero if rolled back)
  # @yield [Factbase] Block to execute in transaction
  def txn(&)
    @mutex.synchronize do
      @origin.txn(&)
    end
  end
end
