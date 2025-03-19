# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
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
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Query
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
  # @return [Integer] Total number of facts yielded
  def each(fb = @fb, params = {})
    return to_enum(__method__, fb, params) unless block_given?
    yielded = 0
    params = params.transform_keys(&:to_s) if params.is_a?(Hash)
    maybe = @term.predict(@maps, params)
    (maybe || @maps).each do |m|
      extras = {}
      f = Factbase::Fact.new(m)
      f = Factbase::Tee.new(f, params)
      a = Factbase::Accum.new(f, extras, false)
      r = @term.evaluate(a, @maps, fb)
      unless r.is_a?(TrueClass) || r.is_a?(FalseClass)
        raise "Unexpected evaluation result of type #{r.class}, must be Boolean at #{@term.inspect}"
      end
      next unless r
      yield Factbase::Accum.new(f, extras, true)
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
      raise "Incorrect type #{r.class} returned by #{@term.inspect}"
    end
    r
  end

  # Delete all facts that match the query.
  # @param [Factbase] fb The factbase to delete from
  # @return [Integer] Total number of facts deleted
  def delete!(fb = @fb)
    deleted = 0
    @maps.delete_if do |m|
      f = Factbase::Fact.new(m)
      if @term.evaluate(f, @maps, fb)
        deleted += 1
        true
      else
        false
      end
    end
    deleted
  end
end
