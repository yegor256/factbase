# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'base'
# Term 'compare'.
# Compares two values using a specified operation.
class Factbase::Compare < Factbase::TermBase
  # Constructor.
  # @param [Symbol] operation Operation to perform, e.g. :>, :<, :<=, :>=, :==
  # @param [Array] operands Operands
  def initialize(operation, operands)
    super()
    @op = operation
    @operands = operands
  end

  # Evaluate term on a fact.
  # @param [Factbase::Fact] fact The fact
  # @param [Array<Factbase::Fact>] maps All maps available
  # @param [Factbase] fb Factbase to use for sub-queries
  # @return [Boolean] The result of the comparison
  def evaluate(fact, maps, fb)
    assert_args(2)
    lefts = _values(0, fact, maps, fb)
    return false if lefts.nil?
    rights = _values(1, fact, maps, fb)
    return false if rights.nil?
    _search(lefts, rights)
  end

  private

  # Look for a pairing that answers true, skipping the ones that cannot be
  # compared at all. The failure is raised only when no pairing was comparable.
  # @param [Array] lefts Left values
  # @param [Array] rights Right values
  # @return [Boolean] The result of the comparison
  def _search(lefts, rights)
    failure = nil
    comparable = false
    lefts.each do |l|
      left = l.is_a?(Time) ? l.floor : l
      rights.each do |r|
        right = r.is_a?(Time) ? r.floor : r
        begin
          answer = _compare(left, right)
        rescue RuntimeError => e
          failure ||= e
          next
        end
        comparable = true
        return true if answer
      end
    end
    raise(failure) unless comparable || failure.nil?
    false
  end

  # Compare values with a contextual error if Ruby rejects the operands.
  # @param [Object] left Left value
  # @param [Object] right Right value
  # @return [Boolean] The result of the comparison
  def _compare(left, right)
    left.__send__(@op, right)
  rescue ArgumentError, NoMethodError, TypeError => e
    raise(
      RuntimeError,
      "Cannot compare #{left.inspect} (#{left.class}) " \
      "with #{right.inspect} (#{right.class}) using (compare #{@op}): #{e.message}"
    )
  end
end
