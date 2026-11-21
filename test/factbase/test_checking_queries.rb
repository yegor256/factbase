# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase/inv'
require_relative '../../lib/factbase/rules'
require_relative '../test__helper'

# Query evaluation must keep the checking factbase supplied to its decorator.
class TestCheckingQueries < Factbase::Test
  def test_invariant_checks_scalar_evaluation
    assert_checked(:invariant, :one)
  end

  def test_invariant_checks_deletion_evaluation
    assert_checked(:invariant, :delete!)
  end

  def test_rules_check_scalar_evaluation
    assert_checked(:rules, :one)
  end

  def test_rules_check_deletion_evaluation
    assert_checked(:rules, :delete!)
  end

  def test_scalar_evaluation_forwards_parameters_and_an_explicit_factbase
    base = Factbase.new
    base.insert.safe = 1
    [guard(base, :invariant), guard(base, :rules)].each do |checked|
      assert_equal('value', checked.query('(at 0 $label)').one(checked, label: ['value']))
      assert_equal(1, checked.query('(agg (always) (count))').one)
      assert_equal(1, checked.query('(agg (always) (count))').one(Factbase.new))
    end
  end

  private

  def assert_checked(kind, operation)
    base = Factbase.new
    base.insert.safe = 1
    name = "checked_#{kind}_#{operation.to_s.delete('!')}"
    result = operation == :one ? 42 : false
    base.query("(defn #{name} \"fb.query('(always)').each { |row| row.forbidden = 1 }; #{result}\")").each.to_a
    checked = guard(base, kind)
    [false, true].each do |explicit|
      query = checked.query("(#{name})")
      error =
        assert_raises(Factbase::Term::Wrapped) do
          explicit ? query.public_send(operation, checked) : query.public_send(operation)
        end
      assert_match(/forbidden/, error.message)
      assert_nil(base.query('(always)').first['forbidden'], error.message)
      assert_equal(1, base.size)
    end
    assert_equal(operation == :one ? result : 0, checked.query("(#{name})").public_send(operation, base))
    assert_equal([1], base.query('(always)').first['forbidden'])
  ensure
    base.query("(undef #{name})").each.to_a
  end

  def guard(base, kind)
    return Factbase::Rules.new(base, '(absent forbidden)') if kind == :rules
    Factbase::Inv.new(base) { |property, _value| raise(RuntimeError, 'forbidden property') if property == 'forbidden' }
  end
end
