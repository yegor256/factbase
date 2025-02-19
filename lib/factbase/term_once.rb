# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'

# Term with a cache, a decorator of another term.
#
# It is NOT thread-safe!
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::TermOnce < Factbase::Term
  # Constructor.
  # @param [Factbase::Term] term Original term
  # @param [Hash] cache The cache
  def initialize(term, cache)
    super(nil, nil, nil) # just to please Rubocop
    @term = term
    @cache = cache
    @text = @term.to_s
    @cacheable = @term.static? && !@term.abstract?
  end

  # Does it match the fact?
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @return [bool] TRUE if matches
  def evaluate(fact, maps)
    return @term.evaluate(fact, maps) unless @cacheable
    key = [@text, maps.object_id]
    before = @cache[key]
    @cache[key] = @term.evaluate(nil, maps) if before.nil?
    @cache[key]
  end

  # Simplify it if possible.
  # @return [Factbase::Term] New term or itself
  def simplify
    @term.simplify
  end

  # Does it have any dependencies on a fact?
  #
  # If a term is static, it will return the same value for +evaluate+,
  # no matter what is the fact given.
  #
  # @return [Boolean] TRUE if static
  def static?
    @term.static?
  end

  # Does it have any variables (+$foo+, for example) inside?
  #
  # @return [Boolean] TRUE if abstract
  def abstract?
    @term.abstract?
  end

  # Turns it into a string.
  # @return [String] The string of it
  def to_s
    @term.to_s
  end
end
