# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'elapsed'
require 'loog'
require 'timeout'
require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestIndexedFactbase < Factbase::Test
  def test_queries_after_update
    origin = Factbase.new
    fb = Factbase::IndexedFactbase.new(origin)
    fb.insert.foo = 42
    fb.query('(exists foo)').each do |f|
      f.bar = 33
    end
    refute_empty(origin.query('(exists bar)').each.to_a)
    refute_empty(fb.query('(exists bar)').each.to_a)
  end

  def test_queries_after_update_in_txn
    [
      '(exists boom)',
      '(one boom)',
      '(and (exists boom) (exists boom))',
      '(and (exists boom) (exists boom) (exists boom))',
      '(and (one boom) (one boom))',
      '(and (one boom) (one foo))',
      '(and (one boom) (one boom) (one boom))',
      '(and (one boom) (one boom) (one boom) (one foo))',
      '(and (one boom) (exists boom))',
      '(and (exists boom) (one boom) (one boom))',
      '(and (exists boom) (exists boom) (one boom))',
      '(and (eq foo 42) (exists boom) (one boom) (not (exists bar)))'
    ].each do |q|
      origin = Factbase.new
      fb = Factbase::IndexedFactbase.new(origin)
      f = fb.insert
      f.foo = 42
      f.boom = 33
      fb.txn do |fbt|
        fbt.query(q).each do |n|
          n.bar = n.foo + 1
        end
      end
      refute_empty(origin.query('(exists bar)').each.to_a, q)
      refute_empty(fb.query('(exists bar)').each.to_a, q)
    end
  end

  def test_queries_after_insert_in_txn
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.txn(&:insert)
    refute_empty(fb.query('(always)').each.to_a)
  end

  def test_works_with_huge_dataset
    fb = Factbase.new
    fb = Factbase::IndexedFactbase.new(fb)
    100_000.times do |i|
      fb.insert.then do |f|
        f.id = i
        f.foo = [42, 1, 256, 7, 99].sample
        f.bar = 'hello'
        f.rarely = rand if rand > 0.95
        f.often = rand if rand > 0.05
      end
    end
    [
      '(and (eq foo 42) (exists bar))',
      '(and (eq foo 42) (exists rarely))',
      '(and (eq foo 42) (exists often))',
      '(and (eq foo 42) (exists often) (exists bar) (absent rarely))',
      '(and (eq foo 42) (empty (eq foo 888)))',
      '(and (eq foo 42) (empty (eq foo $id)))',
      '(and (eq foo 42) (empty (eq foo $often)))',
      '(and (eq foo 42) (empty (exists another)))'
    ].each do |q|
      Timeout.timeout(4) do
        elapsed(Loog::NULL, good: q) do
          refute_empty(fb.query(q).each.to_a)
        end
      end
    end
  end
end
