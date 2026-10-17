# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# The Factbase::Unique class provides functionality for evaluating the uniqueness
# of terms based on provided operands and facts.
class Factbase::Unique < Factbase::TermBase
  # Constructor.
  # @param [Array] operands Operands
  def initialize(operands)
    super()
    @operands = operands
    @seen = Set.new
  end

  # Forget the tuples seen while earlier facts were evaluated.
  # @return [Set] The tuples left, none of them
  def forget
    (Thread.current[:"_fb_unique_#{object_id}"] ||= []).push(Set.new)
    @seen.clear
  end

  # Finish evaluation and clean up scoped seen set.
  def finish
    stack = Thread.current[:"_fb_unique_#{object_id}"]
    return if stack.nil?
    stack.pop
    Thread.current[:"_fb_unique_#{object_id}"] = nil if stack.empty?
  end

  # Clone the term with an isolated seen set.
  # @return [Factbase::Unique] Cloned instance with fresh seen set
  def clone
    super.tap { |c| c.instance_variable_set(:@seen, Set.new) }
  end

  # Duplicate the term with an isolated seen set.
  # @return [Factbase::Unique] Duplicated instance with fresh seen set
  def dup
    super.tap { |c| c.instance_variable_set(:@seen, Set.new) }
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] True if the value is unique, false otherwise
  def evaluate(fact, maps, fb)
    raise(ArgumentError, "Too few operands for 'unique' (at least 1 expected)") if @operands.empty?
    vv = (0..(@operands.size - 1)).map { |i| _values(i, fact, maps, fb) }
    return false if vv.any?(nil)
    tuples = Enumerator.product(*vv).to_a
    seen = Thread.current[:"_fb_unique_#{object_id}"]&.last || @seen
    tuples.filter_map { |t| seen.add?(t) }.any?
  end
end
