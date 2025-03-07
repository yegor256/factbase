# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require_relative '../../factbase'
require_relative '../../factbase/syntax'

# A factbase with a cache.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::CachedFactbase
  decoor(:origin)

  # Constructor.
  # @param [Factbase] origin Original factbase to decorate
  # @param [Hash] cache Cache to use
  def initialize(origin, cache = {})
    @origin = origin
    @cache = cache
  end

  # Insert a new fact and return it.
  # @return [Factbase::Fact] The fact just inserted
  def insert
    @cache.clear
    require_relative 'cached_fact'
    Factbase::CachedFact.new(@origin.insert, @cache)
  end

  # Convert a query to a term.
  # @param [String] query The query to convert
  # @return [Factbase::Term] The term
  def to_term(query)
    require_relative 'cached_term'
    @origin.to_term(query).redress(Factbase::CachedTerm, cache: @cache, fb: self)
  end

  # Create a query capable of iterating.
  # @param [String] term The term to use
  # @param [Array<Hash>] maps Possible maps to use
  def query(term, maps = nil)
    term =
      if term.is_a?(String)
        to_term(term)
      else
        term.redress(Factbase::CachedTerm, cache: @cache, fb: self)
      end
    q = @origin.query(term, maps)
    unless term.abstract?
      require_relative 'cached_query'
      q = Factbase::CachedQuery.new(q, @cache)
    end
    q
  end

  # Run an ACID transaction.
  # @return [Factbase::Churn] How many facts have been changed (zero if rolled back)
  def txn
    @origin.txn do |fbt|
      yield Factbase::CachedFactbase.new(fbt, @cache)
    end
  end
end
