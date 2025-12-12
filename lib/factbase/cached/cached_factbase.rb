# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require_relative '../../factbase'
require_relative '../../factbase/syntax'
require_relative 'cached_fact'
require_relative 'cached_query'
require_relative 'cached_term'

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
    raise 'Wrong type of original' unless origin.respond_to?(:query)
    @origin = origin
    raise 'Wrong type of cache' unless cache.is_a?(Hash)
    @cache = cache
  end

  # Insert a new fact and return it.
  # @return [Factbase::Fact] The fact just inserted
  def insert
    @cache[:__dirty__] = true
    Factbase::CachedFact.new(@origin.insert, @cache, fresh: true)
  end

  # Convert a query to a term.
  # @param [String] query The query to convert
  # @return [Factbase::Term] The term
  def to_term(query)
    t = @origin.to_term(query)
    t.redress!(Factbase::CachedTerm, cache: @cache)
    t
  end

  # Create a query capable of iterating.
  # @param [String] term The term to use
  # @param [Array<Hash>] maps Possible maps to use
  def query(term, maps = nil)
    term = to_term(term) if term.is_a?(String)
    q = @origin.query(term, maps)
    q = Factbase::CachedQuery.new(q, @cache, self) unless term.abstract?
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
