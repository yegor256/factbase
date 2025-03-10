# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'
require_relative 'accum'
require_relative 'fact'
require_relative 'syntax'
require_relative 'tee'

# Iterator.
#
# This is an internal class, it is not supposed to be instantiated directly.
#
# It is NOT thread-safe!
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Iterator
  # Constructor.
  # @param [Array<Fact>] maps Array of facts to start with
  # @param [Factbase::Term] term The query term
  def initialize(maps, term)
    @maps = maps
    @term = term
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
  def each(fb, params = {})
    yielded = 0
    params = params.transform_keys(&:to_s) if params.is_a?(Hash)
    @term.predict(@maps).each do |m|
      extras = {}
      f = Factbase::Fact.new(m)
      f = Factbase::Tee.new(f, params)
      a = Factbase::Accum.new(f, extras, false)
      r = @term.evaluate(a, @maps, fb)
      yield [r, Factbase::Accum.new(f, extras, true)]
      yielded += 1
    end
    yielded
  end
end
