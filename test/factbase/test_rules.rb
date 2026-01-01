# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/rules'
require_relative '../../lib/factbase/pre'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestRules < Factbase::Test
  def test_simple_checking
    fb = Factbase::Rules.new(
      Factbase.new,
      '(when (exists first) (exists second))'
    )
    f1 = fb.insert
    f1.second = 2
    f1.first = 1
    f2 = fb.insert
    assert_raises(StandardError) do
      f2.first = 1
    end
  end

  def test_check_with_id
    fb = Factbase::Rules.new(Factbase.new, '(exists foo)', uid: 'id')
    fb.txn do |fbt|
      f = fbt.insert
      f.foo = 42
    end
  end

  def test_to_string
    fb = Factbase::Rules.new(
      Factbase.new,
      '(when (exists a) (exists b))'
    )
    f = fb.insert
    f.foo = 42
    s = f.to_s
    assert_predicate(s.length, :positive?, s)
    assert_equal('[ foo: [42] ]', s)
  end

  def test_query_one
    fb = Factbase::Rules.new(Factbase.new, '(always)')
    f = fb.insert
    f.foo = 42
    assert_equal(1, fb.query('(agg (eq foo $v) (count))').one(Factbase.new, v: 42))
  end

  def test_check_only_when_txn_is_closed
    fb = Factbase::Rules.new(Factbase.new, '(when (exists a) (exists b))')
    ok = false
    assert_raises(StandardError) do
      fb.txn do |fbt|
        f = fbt.insert
        f.a = 1
        f.c = 2
        ok = true
      end
    end
    assert(ok)
  end

  def test_rollback_on_violation
    fb = Factbase::Rules.new(Factbase.new, '(when (exists a) (exists b))')
    assert_raises(StandardError) do
      fb.txn do |fbt|
        f = fbt.insert
        f.a = 1
        f.c = 2
      end
    end
    assert_equal(0, fb.size)
  end

  def test_defends_against_id_duplicates
    fb = Factbase::Rules.new(Factbase.new, '(always)', uid: 'id')
    assert_raises(StandardError) do
      fb.txn do |fbt|
        fbt.insert.then do |f|
          f.id = 1
          f.id = 2
        end
      end
    end
  end

  def test_fails_if_id_duplicates_are_there_already
    fb = Factbase::Rules.new(Factbase.new, '(always)', uid: 'id')
    fb.insert.then do |f|
      f.id = 1
      f.id = 2
    end
    assert_raises(StandardError) do
      fb.txn do |fbt|
        fbt.insert.then do |f|
          f.foo = 42
        end
      end
    end
  end

  def test_in_combination_with_pre
    fb = Factbase::Rules.new(Factbase.new, '(when (exists a) (exists b))')
    fb =
      Factbase::Pre.new(fb) do |f|
        f.hello = 42
      end
    ok = false
    assert_raises(StandardError) do
      fb.txn do |fbt|
        f = fbt.insert
        f.a = 1
        f.c = 2
        ok = true
      end
    end
    assert(ok)
    assert_equal(0, fb.query('(eq hello $v)').each(v: 42).to_a.size)
  end
end
