# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/churn'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestChurn < Factbase::Test
  def test_appends
    c = Factbase::Churn.new
    c.append(1, 2, 3)
    assert_equal('1i/2d/3a', c.to_s)
    assert_equal(6, c.to_i)
  end

  def test_converts_empty_to_string
    assert_equal('nothing', Factbase::Churn.new.to_s)
  end

  def test_converts_to_string_with_single_non_zero_counter
    assert_equal('1i/0d/0a', Factbase::Churn.new(1, 0, 0).to_s)
    assert_equal('0i/2d/0a', Factbase::Churn.new(0, 2, 0).to_s)
    assert_equal('0i/0d/5a', Factbase::Churn.new(0, 0, 5).to_s)
  end

  def test_converts_to_string_with_two_non_zero_counters
    assert_equal('1i/2d/0a', Factbase::Churn.new(1, 2, 0).to_s)
    assert_equal('3i/0d/4a', Factbase::Churn.new(3, 0, 4).to_s)
    assert_equal('0i/5d/6a', Factbase::Churn.new(0, 5, 6).to_s)
  end

  def test_converts_to_string_with_partial_counters_via_append
    c1 = Factbase::Churn.new
    c1.append(4, 0, 0)
    assert_equal('4i/0d/0a', c1.to_s)
    c2 = Factbase::Churn.new
    c2.append(0, 7, 0)
    assert_equal('0i/7d/0a', c2.to_s)
    c3 = Factbase::Churn.new
    c3.append(0, 0, 9)
    assert_equal('0i/0d/9a', c3.to_s)
    c4 = Factbase::Churn.new
    c4.append(2, 8, 0)
    assert_equal('2i/8d/0a', c4.to_s)
  end

  def test_only_all_zero_counters_produce_nothing
    [
      [0, 0, 0, 'nothing'],
      [1, 0, 0, '1i/0d/0a'],
      [0, 2, 0, '0i/2d/0a'],
      [0, 0, 3, '0i/0d/3a'],
      [1, 2, 0, '1i/2d/0a'],
      [1, 0, 3, '1i/0d/3a'],
      [0, 2, 3, '0i/2d/3a'],
      [4, 5, 6, '4i/5d/6a']
    ].each do |ins, del, add, expected|
      churn = Factbase::Churn.new(ins, del, add)
      if ins.zero? && del.zero? && add.zero?
        assert_equal('nothing', churn.to_s)
      else
        refute_equal('nothing', churn.to_s)
        assert_equal(expected, churn.to_s)
      end
    end
  end

  def test_checks_for_zero
    assert_predicate(Factbase::Churn.new, :zero?)
  end

  def test_makes_a_duplicate
    assert_predicate(Factbase::Churn.new.dup, :zero?)
  end

  def test_concatenates_with_other
    c1 = Factbase::Churn.new
    c1.append(1, 6, 3)
    c2 = Factbase::Churn.new
    c2.append(3, 2, 46)
    assert_equal('4i/8d/49a', (c1 + c2).to_s)
  end

  def test_reads_the_counters_under_the_lock_of_append
    churn = Factbase::Churn.new
    churn.append(1, 1, 1)
    %i[inserted deleted added to_i to_s zero?].each do |reader|
      churn.instance_variable_get(:@mutex).synchronize do
        t = Thread.new { churn.public_send(reader) }
        sleep(0.05)
        assert_predicate(t, :alive?, "#{reader} read the counters without the lock")
        t.kill
      end
    end
  end
end
