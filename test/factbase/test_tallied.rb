# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'threads'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/tallied'
require_relative '../../lib/factbase/term'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTallied < Factbase::Test
  def test_counts_size
    assert_equal(0, Factbase::Tallied.new(Factbase.new).size)
  end

  def test_queries_empty_factbase
    assert_equal(0, Factbase::Tallied.new(Factbase.new).query('(gt foo 1)').each.to_a.size)
  end

  def test_counts_simple_changes
    fb = Factbase::Tallied.new(Factbase.new)
    fb.insert.bar = 3
    fb.query('(exists bar)').each do |f|
      f.foo = 42
    end
    assert_equal(1, fb.churn.inserted)
    assert_equal(0, fb.churn.deleted)
    assert_equal(2, fb.churn.added)
  end

  def test_counts_in_one
    fb = Factbase::Tallied.new(Factbase.new)
    fb.insert.bar = 3
    assert_equal(1, fb.query('(agg (eq bar 3) (count))').one)
    assert_equal(1, fb.churn.added)
  end

  def test_returns_all_props
    f = Factbase::Tallied.new(Factbase.new).insert
    f.bar = 3
    assert_includes(f.all_properties, 'bar')
  end

  def test_counts_in_txn
    fb = Factbase::Tallied.new(Factbase.new)
    fb.txn do |fbt|
      fbt.insert.boom = 3
      fbt.query('(exists boom)').each do |f|
        f.foo = 88
      end
    end
    assert_equal(1, fb.churn.inserted)
    assert_equal(0, fb.churn.deleted)
    assert_equal(2, fb.churn.added)
  end

  def test_counts_in_txn_after_rollback
    fb = Factbase::Tallied.new(Factbase.new)
    fb.txn do |fbt|
      fbt.insert.boom = 3
      raise(Factbase::Rollback)
    end
    assert_predicate(fb.churn, :zero?)
  end

  def test_counts_in_txn_after_rollback_throw
    fb = Factbase::Tallied.new(Factbase.new)
    fb.txn do |fbt|
      fbt.insert.boom = 3
      throw(:rollback)
    end
    assert_predicate(fb.churn, :zero?)
  end

  def test_counts_in_txn_in_threads
    fb = Factbase::Tallied.new(Factbase.new)
    t = 5
    Threads.new(t).assert do |i|
      fb.txn do |fbt|
        fbt.insert.x = i
        fbt.query("(eq x #{i})").each do |f|
          f.__send__(:"a#{i}=", i)
        end
        fbt.query("(lt x #{t + 1})").delete!
      end
    end
    assert_equal(0, fb.size)
    assert_equal(t, fb.churn.inserted)
    assert_equal(t, fb.churn.deleted)
    assert_equal(t * 2, fb.churn.added)
  end

  def test_counts_imported_facts
    src = Factbase.new
    3.times { |i| src.insert.foo = i }
    fb = Factbase::Tallied.new(Factbase.new)
    fb.import(src.export)
    assert_equal(3, fb.size)
    assert_equal(3, fb.churn.inserted, 'Imported facts must be counted as inserted')
  end

  def test_counts_churn_in_one_with_default_context
    n = :_churn_in_one_default
    Factbase::Term.new(:defn, [n, 'fb.insert.value = 2; fb.size']).evaluate(nil, [], Factbase.new)
    begin
      fb = Factbase::Tallied.new(Factbase.new)
      assert_equal(1, fb.query("(#{n})").one)
      assert_equal(1, fb.churn.inserted)
      assert_equal(0, fb.churn.deleted)
      assert_equal(1, fb.churn.added)
      assert_equal(1, fb.size)
    ensure
      Factbase::Term.new(:undef, [n]).evaluate(nil, [], Factbase.new)
    end
  end

  def test_counts_churn_in_one_with_explicit_context
    n = :_churn_in_one_explicit
    Factbase::Term.new(:defn, [n, 'fb.insert.value = 2; fb.size']).evaluate(nil, [], Factbase.new)
    begin
      fb = Factbase::Tallied.new(Factbase.new)
      assert_equal(1, fb.query("(#{n})").one(fb))
      assert_equal(1, fb.churn.inserted)
      assert_equal(0, fb.churn.deleted)
      assert_equal(1, fb.churn.added)
      assert_equal(1, fb.size)
    ensure
      Factbase::Term.new(:undef, [n]).evaluate(nil, [], Factbase.new)
    end
  end

  def test_query_default_context_matches_explicit_context_churn
    n = :_churn_context_match
    Factbase::Term.new(:defn, [n, 'fb.insert.value = 2; fb.size']).evaluate(nil, [], Factbase.new)
    begin
      fb1 = Factbase::Tallied.new(Factbase.new)
      fb2 = Factbase::Tallied.new(Factbase.new)
      assert_equal(fb2.query("(#{n})").one(fb2), fb1.query("(#{n})").one)
      assert_equal(fb2.churn.inserted, fb1.churn.inserted)
      assert_equal(fb2.churn.deleted, fb1.churn.deleted)
      assert_equal(fb2.churn.added, fb1.churn.added)
      assert_equal(fb2.size, fb1.size)
    ensure
      Factbase::Term.new(:undef, [n]).evaluate(nil, [], Factbase.new)
    end
  end
end
