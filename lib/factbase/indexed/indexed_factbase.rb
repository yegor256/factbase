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
    Factbase::IndexedFact.new(@origin.insert, @idx, fresh: true)
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
    result =
      @origin.txn do |fbt|
        yield Factbase::IndexedFactbase.new(fbt, @idx)
      end
    @idx.clear
    result
  end

  # Export it into a chain of bytes, including both data and index.
  #
  # Here is how you can export it to a file, for example:
  #
  #  fb = Factbase::IndexedFactbase.new(Factbase.new)
  #  fb.insert.foo = 42
  #  File.binwrite("foo.fb", fb.export)
  #
  # The data is binary, it's not a text!
  #
  # @return [String] Binary string containing serialized data and index
  def export
    Marshal.dump({ maps: @origin.export, idx: @idx })
  end

  # Import from a chain of bytes, including both data and index.
  #
  # Here is how you can read it from a file, for example:
  #
  #  fb = Factbase::IndexedFactbase.new(Factbase.new)
  #  fb.import(File.binread("foo.fb"))
  #
  # The facts that existed in the factbase before importing will remain there.
  # The facts from the incoming byte stream will be added to them.
  # If the byte stream doesn't contain an index (for backward compatibility),
  # the index will be empty and will be built on first use.
  #
  # @param [String] bytes Binary string to import
  def import(bytes)
    raise 'Empty input, cannot load a factbase' if bytes.empty?
    data = Marshal.load(bytes)
    if data.is_a?(Hash) && data.key?(:maps)
      @origin.import(data[:maps])
      @idx.merge!(data[:idx]) if data[:idx].is_a?(Hash)
    else
      @origin.import(bytes)
      @idx.clear
    end
  end

  # Size, the total number of facts in the factbase.
  # @return [Integer] How many facts are in there
  def size
    @origin.size
  end
end
