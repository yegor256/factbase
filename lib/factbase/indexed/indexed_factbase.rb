# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require_relative '../../factbase'
require_relative '../../factbase/syntax'
require_relative 'indexed_fact'
require_relative 'indexed_query'
require_relative 'indexed_term'

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
    raise 'Wrong type of original' unless origin.respond_to?(:query)
    @origin = origin
    raise 'Wrong type of index' unless idx.is_a?(Hash)
    @idx = idx
  end

  # Insert a new fact and return it.
  # @return [Factbase::Fact] The fact just inserted
  def insert
    @idx.clear
    Factbase::IndexedFact.new(@origin.insert, @idx)
  end

  # Convert a query to a term.
  # @param [String] query The query to convert
  # @return [Factbase::Term] The term
  def to_term(query)
    t = @origin.to_term(query)
    t.redress!(Factbase::IndexedTerm, idx: @idx)
    t
  end

  # Create a query capable of iterating.
  # @param [String] term The term to use
  # @param [Array<Hash>] maps Possible maps to use
  def query(term, maps = nil)
    term = to_term(term) if term.is_a?(String)
    q = @origin.query(term, maps)
    q = Factbase::IndexedQuery.new(q, @idx, self) if term.abstract?
    q
  end

  # Run an ACID transaction.
  # @return [Factbase::Churn] How many facts have been changed (zero if rolled back)
  def txn
    @origin.txn do |fbt|
      yield Factbase::IndexedFactbase.new(fbt, @idx)
    end
  end
end
