# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Persistence and query-local computations through selectors, including composition.
class TestSelectorWrites < Factbase::Test
  FILTER = '(and (gt num $floor) (as computed (minus 0 num)))'
  SELECTORS = {
    '(head 2 %s)' => [3, 2],
    '(sorted computed %s)' => [3, 2, 2],
    '(inverted %s)' => [2, 2, 3],
    '(head 2 (sorted computed %s))' => [3, 2],
    '(head 2 (inverted %s))' => [2, 2],
    '(sorted computed (head 2 %s))' => [3, 2],
    '(sorted computed (inverted %s))' => [3, 2, 2],
    '(inverted (head 2 %s))' => [2, 3],
    '(inverted (sorted computed %s))' => [2, 2, 3]
  }.freeze

  def test_reads_computed_values_and_persists_only_explicit_writes
    cases do |fb, query, expected|
      found = fb.query(query).each(fb, floor: 1).to_a
      assert_equal(expected, found.map(&:num), query)
      found.each do |f|
        assert_equal(-f.num, f.computed, query)
        assert_equal([-f.num], f['computed'], query)
        f.seen = 1
        f.seen = 2
        f.num = 9
      end
      assert_equal(expected.size, fb.query('(exists seen)').each.count, query)
      assert_equal(expected.size, fb.query('(eq num 9)').each.count, query)
      fb.query('(exists seen)').each { |f| assert_equal([1, 2], f['seen'], query) }
      assert_empty(fb.query('(exists computed)').each.to_a, query)
      fb.query('(always)').each { |f| refute_includes(f.all_properties, 'floor', query) }
      restored = Factbase.new
      restored.import(fb.export)
      assert_equal(expected.size, restored.query('(exists seen)').each.count, query)
      assert_empty(restored.query('(exists computed)').each.to_a, query)
    end
  end

  def test_commit_records_each_changed_fact_once
    cases do |fb, query, expected|
      churn =
        fb.txn do |txn|
          txn.query(query).each(txn, 'floor' => 1) do |f|
            assert_equal([-f.num], f['computed'], query)
            f.seen = 1
            f.seen = 2
          end
          assert_equal(expected.size, txn.query('(exists seen)').each.count, query)
          assert_empty(fb.query('(exists seen)').each.to_a, query)
          throw(:commit)
        end
      assert_equal(expected.size, churn.added, query)
      assert_equal("0i/0d/#{expected.size}a", churn.to_s, query)
      assert_equal(expected.size, fb.query('(exists seen)').each.count, query)
      assert_empty(fb.query('(exists computed)').each.to_a, query)
    end
  end

  def test_read_only_computations_have_no_churn
    cases do |fb, query, expected|
      churn =
        fb.txn do |txn|
          found = txn.query(query).each(txn, floor: 1).to_a
          assert_equal(expected, found.map(&:num), query)
          found.each { |f| assert_equal([-f.num], f['computed'], query) }
        end
      assert_equal('nothing', churn.to_s, query)
      assert_predicate(churn, :zero?, query)
      assert_empty(fb.query('(exists computed)').each.to_a, query)
    end
  end

  def test_rollback_discards_writes_and_churn
    cases do |fb, query, _expected|
      %i[throw raise].each do |mode|
        churn =
          fb.txn do |txn|
            txn.query(query).each(txn, floor: 1) { |f| f.seen = 1 }
            raise(Factbase::Rollback) if mode == :raise
            throw(:rollback)
          end
        assert_equal('nothing', churn.to_s, query)
        assert_predicate(churn, :zero?, query)
        assert_empty(fb.query('(exists seen)').each.to_a, query)
        assert_empty(fb.query('(exists computed)').each.to_a, query)
      end
      assert_raises(RuntimeError) do
        fb.txn do |txn|
          txn.query(query).each(txn, floor: 1) { |f| f.seen = 1 }
          raise(RuntimeError, 'rollback on error')
        end
      end
      assert_empty(fb.query('(exists seen)').each.to_a, query)
    end
  end

  def test_repeated_prediction_does_not_replay_stateful_operands
    [false, true].each do |indexed|
      SELECTORS.each_key do |selector|
        query = fresh(indexed).query(format(selector, '(and (unique num) (as computed (minus 0 num)))'))
        2.times do
          found = query.each.to_a
          assert_operator(found.size, :>=, 2)
          nums = found.map(&:num)
          assert_equal(nums.uniq, nums)
          found.each { |f| assert_equal([-f.num], f['computed']) }
        end
      end
    end
  end

  def test_deletion_through_computed_nested_selectors
    cases do |fb, query, expected|
      assert_equal(expected.size, fb.query(query.gsub('$floor', '1')).delete!, query)
      assert_equal(4 - expected.size, fb.size, query)
      assert_empty(fb.query('(exists computed)').each.to_a, query)
    end
  end

  def test_transactional_deletion_records_churn
    cases do |fb, query, expected|
      churn =
        fb.txn do |txn|
          assert_equal(expected.size, txn.query(query.gsub('$floor', '1')).delete!, query)
          assert_equal(4 - expected.size, txn.size, query)
          assert_equal(4, fb.size, query)
        end
      assert_equal(expected.size, churn.deleted, query)
      assert_equal("0i/#{expected.size}d/0a", churn.to_s, query)
      assert_equal(4 - expected.size, fb.size, query)
    end
  end

  private

  def fresh(indexed)
    fb = Factbase.new
    fb = Factbase::IndexedFactbase.new(fb) if indexed
    [3, 1, 2, 2].each_with_index do |num, idx|
      f = fb.insert
      f.num = num
      f.serial = idx
    end
    fb
  end

  def cases
    [false, true].each do |indexed|
      SELECTORS.each do |selector, expected|
        yield(fresh(indexed), format(selector, FILTER), expected)
      end
    end
  end
end
