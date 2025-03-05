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
  # @param [Array<Hash>] maps Array of facts to start with
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
  # @param [String] query The query to use for selections
  def query(query)
    @mutex.synchronize do
      require_relative 'sync_query'
      Factbase::SyncQuery.new(@origin.query(query), @mutex)
    end
  end

  # Run an ACID transaction.
  # @return [Factbase::Churn] How many facts have been changed (zero if rolled back)
  def txn(&)
    @mutex.synchronize do
      @origin.txn(&)
    end
  end
end
