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

  # Convert a query to a term.
  # @param [String] query The query to convert
  # @return [Factbase::Term] The term
  def to_term(query)
    require_relative 'indexed_term'
    @origin.to_term(query).redress(Factbase::IndexedTerm, idx: @idx, fb: self)
  end

  # Create a query capable of iterating.
  # @param [String] term The term to use
  # @param [Array<Hash>] maps Possible maps to use
  def query(term, maps = nil)
    term =
      if term.is_a?(String)
        to_term(term)
      else
        require_relative 'indexed_term'
        term.redress(Factbase::IndexedTerm, idx: @idx, fb: self)
      end
    q = @origin.query(term, maps)
    unless term.abstract?
      require_relative 'indexed_query'
      q = Factbase::IndexedQuery.new(q, @idx)
    end
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
