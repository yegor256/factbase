# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Term with a cache.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::CachedTerm < Factbase::Term
  # Ctor.
  # @param [Symbol] operator Operator
  # @param [Array] operands Operands
  # @param [Factbase] fb Optional factbase reference
  def initialize(operator, operands, fb: nil)
    super
    @cacheable = static? && !abstract?
  end

  # Inject cache into this term and all others inside.
  # @param [Hash] cache The cache
  def inject_cache(cache)
    @cache = cache
    @operands.each do |o|
      next unless o.is_a?(Factbase::CachedTerm)
      o.inject_cache(cache)
    end
  end

  # Does it match the fact?
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @return [bool] TRUE if matches
  def evaluate(fact, maps)
    return super unless @cacheable
    key = [@text, maps.object_id]
    before = @cache[key]
    @cache[key] = super if before.nil?
    @cache[key]
  end
end
