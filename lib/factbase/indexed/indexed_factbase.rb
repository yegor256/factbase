# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require_relative '../../factbase'
require_relative '../../factbase/syntax'

# A factbase with an index.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::IndexedFactbase
  decoor(:origin)

  # Constructor.
  # @param [Factbase] origin Original factbase to decorate
  # @param [Hash] idx Index to use
  def initialize(origin, idx = {})
    @origin = origin
    @idx = idx
  end

  # Insert a new fact and return it.
  # @return [Factbase::Fact] The fact just inserted
  def insert
    @idx.clear
    require_relative 'indexed_fact'
    Factbase::IndexedFact.new(@origin.insert, @idx)
  end

  # Create a query capable of iterating.
  # @param [String] term The term to use
  # @param [Array<Hash>] maps Possible maps to use
  def query(term, maps = nil)
    term = Factbase::Syntax.new(term).to_term(self) if term.is_a?(String)
    require_relative 'indexed_query'
    Factbase::IndexedQuery.new(@origin.query(term, maps), @idx)
  end

  # Run an ACID transaction.
  # @return [Factbase::Churn] How many facts have been changed (zero if rolled back)
  def txn
    @origin.txn do |fbt|
      yield Factbase::IndexedFactbase.new(fbt, @idx)
    end
  end
end
