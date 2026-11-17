# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'time'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedRangeTime < Factbase::Test
  def test_keeps_a_fact_inside_the_same_second
    moment = Time.parse('2024-01-01T00:00:01.9Z')
    target = Time.parse('2024-01-01T00:00:01.99Z')
    %w[gt gte lt lte].each do |op|
      origin = Factbase.new
      origin.insert.when = moment
      indexed = Factbase::IndexedFactbase.new(Factbase.new)
      indexed.insert.when = moment
      query = "(#{op} when $t)"
      assert_equal(
        origin.query(query).each(origin, { 't' => [target] }).to_a.size,
        indexed.query(query).each(indexed, { 't' => [target] }).to_a.size,
        query
      )
    end
  end

  def test_keeps_a_fact_when_later_inside_the_same_second
    moment = Time.parse('2024-01-01T00:00:01.99Z')
    target = Time.parse('2024-01-01T00:00:01.9Z')
    %w[gt gte lt lte].each do |op|
      origin = Factbase.new
      origin.insert.when = moment
      indexed = Factbase::IndexedFactbase.new(Factbase.new)
      indexed.insert.when = moment
      query = "(#{op} when $t)"
      assert_equal(
        origin.query(query).each(origin, { 't' => [target] }).to_a.size,
        indexed.query(query).each(indexed, { 't' => [target] }).to_a.size,
        query
      )
    end
  end

  def test_keeps_a_fact_at_floor_second_boundary
    moment = Time.parse('2024-01-01T00:00:01.999999Z')
    target = Time.parse('2024-01-01T00:00:01.0Z')
    %w[gt gte lt lte].each do |op|
      origin = Factbase.new
      origin.insert.when = moment
      indexed = Factbase::IndexedFactbase.new(Factbase.new)
      indexed.insert.when = moment
      query = "(#{op} when $t)"
      assert_equal(
        origin.query(query).each(origin, { 't' => [target] }).to_a.size,
        indexed.query(query).each(indexed, { 't' => [target] }).to_a.size,
        query
      )
    end
  end

  def test_lte_matches_multiple_facts_across_second_boundaries
    times = [
      Time.parse('2024-01-01T00:00:00.8Z'),
      Time.parse('2024-01-01T00:00:01.2Z'),
      Time.parse('2024-01-01T00:00:01.99Z'),
      Time.parse('2024-01-01T00:00:02.1Z')
    ]
    origin = Factbase.new
    indexed = Factbase::IndexedFactbase.new(Factbase.new)
    times.each do |time|
      origin.insert.when = time
      indexed.insert.when = time
    end
    target = Time.parse('2024-01-01T00:00:01.5Z')
    query = '(lte when $t)'
    assert_equal(
      origin.query(query).each(origin, { 't' => [target] }).to_a.size,
      indexed.query(query).each(indexed, { 't' => [target] }).to_a.size,
      query
    )
    assert_equal(3, indexed.query(query).each(indexed, { 't' => [target] }).to_a.size)
  end

  def test_lte_with_literal_time_later_in_same_second
    moment = Time.parse('2024-01-01T00:00:01.99Z')
    origin = Factbase.new
    origin.insert.when = moment
    indexed = Factbase::IndexedFactbase.new(Factbase.new)
    indexed.insert.when = moment
    query = '(lte when 2024-01-01T00:00:01.1Z)'
    assert_equal(origin.query(query).each(origin).to_a.size, indexed.query(query).each(indexed).to_a.size, query)
    assert_equal(1, indexed.query(query).each(indexed).to_a.size)
  end

  def test_lte_excludes_fact_in_next_second
    indexed = Factbase::IndexedFactbase.new(Factbase.new)
    indexed.insert.when = Time.parse('2024-01-01T00:00:02.0Z')
    assert_equal(0, indexed.query('(lte when 2024-01-01T00:00:01.99Z)').each(indexed).to_a.size)
  end
end
