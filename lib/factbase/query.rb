# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'
require_relative 'accum'
require_relative 'fact'
require_relative 'syntax'
require_relative 'tee'

# Query.
#
# This is an internal class, it is not supposed to be instantiated directly. It
# is created by the +query()+ method of the +Factbase+ class.
#
# It is NOT thread-safe!
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Query
  include Enumerable

  # Constructor.
  # @param [Array<Fact>] maps Array of facts to start with
  # @param [String|Factbase::Term] term The query term
  def initialize(maps, term, fb)
    @maps = maps
    @term = term.is_a?(String) ? Factbase::Syntax.new(term).to_term : term
    @fb = fb
  end

  # Print it as a string.
  # @return [String] The query as a string
  def to_s
    @term.to_s
  end

  # Iterate facts one by one.
  # @param [Factbase] fb The factbase
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @yield [Fact] Facts one-by-one
  # @return [Integer] Total number of facts yielded (if block given), otherwise enumerator
  def each(fb = @fb, params = {})
    return to_enum(__method__, fb, params) unless block_given?
    yielded = 0
    params = params.transform_keys(&:to_s) if params.is_a?(Hash)
    maybe = @term.predict(@maps, fb, Factbase::Tee.new({}, params))
    maybe ||= @maps unless maybe.equal?(@maps)
    maybe.each do |m|
      extras = {}
      f = Factbase::Fact.new(m)
      f = Factbase::Tee.new(f, params)
      r = @term.evaluate(Factbase::Accum.new(f, extras, false), @maps, fb)
      unless r.is_a?(TrueClass) || r.is_a?(FalseClass)
        raise(ArgumentError, "Unexpected evaluation result of type #{r.class}, must be Boolean at #{@term}")
      end
      next unless r
      yield(Factbase::Accum.new(f, extras, true))
      yielded += 1
    end
    yielded
  end

  # Read a single value.
  # @param [Factbase] fb The factbase
  # @param [Hash] params Optional params accessible in the query via the "$" symbol
  # @return [String|Integer|Float|Time|Array|NilClass] The value evaluated
  def one(fb = @fb, params = {})
    params = params.transform_keys(&:to_s) if params.is_a?(Hash)
    r = @term.evaluate(Factbase::Tee.new(Factbase::Fact.new({}), params), @maps, fb)
    unless %w[String Integer Float Time Array NilClass].include?(r.class.to_s)
      raise(StandardError, "Incorrect type #{r.class} returned by #{@term}")
    end
    r
  end

  # Delete all facts that match the query.
  #
  # The term is asked about every fact exactly once, and it is asked
  # through the same accumulator that {#each} uses, so a term that writes,
  # like `as`, writes into a throw-away copy and leaves the surviving facts
  # alone, while a term that remembers, like `unique`, is not asked the
  # same question twice (#694).
  #
  # @param [Factbase] fb The factbase to delete from
  # @return [Integer] Total number of facts deleted
  def delete!(fb = @fb)
    deleted = 0
    @maps.delete_if do |m|
      d = @term.evaluate(Factbase::Accum.new(Factbase::Fact.new(m), {}, false), @maps, fb)
      deleted += 1 if d
      d
    end
    deleted
  end
end
