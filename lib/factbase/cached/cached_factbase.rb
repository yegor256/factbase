# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require_relative '../../factbase'
require_relative '../../factbase/syntax'
require_relative '../enumerated'
require_relative 'cached_fact'
require_relative 'cached_query'
require_relative 'cached_term'

# A factbase with a cache.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::CachedFactbase
  decoor(:origin)
  include Factbase::Enumerated

  # Constructor.
  # @param [Factbase] origin Original factbase to decorate
  # @param [Hash] cache Cache to use
  def initialize(origin, cache = {})
    raise(ArgumentError, 'Wrong type of original') unless origin.respond_to?(:query)
    @origin = origin
    raise(ArgumentError, 'Wrong type of cache') unless cache.is_a?(Hash)
    @cache = cache
  end

  # Insert a new fact and return it.
  # @return [Factbase::Fact] The fact just inserted
  def insert
    @cache[:__dirty__] = true
    Factbase::CachedFact.new(@origin.insert, @cache, fresh: true)
  end

  # Import facts from a binary buffer.
  # @param [String] data The data to import
  def import(data)
    @cache.clear
    @origin.import(data)
  end

  # Convert a query to a term.
  # @param [String] query The query to convert
  # @return [Factbase::Term] The term
  def to_term(query)
    t = @origin.to_term(query)
    t.redress!(Factbase::CachedTerm, cache: @cache)
    t
  end

  # Check whether a query or term can be cached.
  # @param [String, Factbase::Term] query The query or term
  # @return [Boolean] TRUE if cacheable
  def cacheable?(query)
    return false if query.is_a?(String) && query.include?('traced')
    term = query.is_a?(String) ? to_term(query) : query
    return false if term.abstract?
    return false if traced?(term)
    true
  end

  # Create a query capable of iterating.
  # @param [String] term The term to use
  # @param [Array<Hash>] maps Possible maps to use
  def query(term, maps = nil)
    term = to_term(term) if term.is_a?(String)
    Factbase::CachedQuery.new(@origin.query(term, maps), @cache, self, cacheable: cacheable?(term))
  end

  # Run an ACID transaction.
  # @return [Factbase::Churn] How many facts have been changed (zero if rolled back)
  def txn
    @origin.txn do |fbt|
      yield(Factbase::CachedFactbase.new(fbt, {}))
    end
  ensure
    @cache.clear
  end

  private

  # Check whether the term or any of its sub-terms is traced.
  # @param [Object] term The term or operand to inspect
  # @return [Boolean] TRUE if traced
  def traced?(term)
    return false unless term.is_a?(Factbase::Term)
    return true if term.op.to_s == 'traced'
    term.operands.any? { |operand| traced?(operand) }
  end
end
