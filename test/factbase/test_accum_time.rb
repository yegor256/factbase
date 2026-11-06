# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/accum'
require_relative '../../lib/factbase/fact'
require_relative '../../lib/factbase/query'
require_relative '../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestAccumTime < Factbase::Test
  def test_yields_a_time_whole
    moment = Time.now
    Factbase::Query.new([{ 'time' => moment }], '(always)', Factbase.new).each do |f|
      assert_equal([moment], f['time'])
    end
  end

  def test_keeps_a_time_set_by_as_in_utc
    fb = Factbase.new
    fb.insert.stamp = '2024-01-01T10:00:00+09:00'
    t = fb.query('(as copy (to_time stamp))').each.first.copy
    assert_equal(Time.utc(2024, 1, 1, 1, 0, 0), t)
    assert_predicate(t, :utc?)
  end

  def test_keeps_a_computed_time_in_utc
    fb = Factbase.new
    fb.insert.id = 1
    f = fb.query("(as later (plus $t '1 hour'))").each(fb, t: [Time.new(2024, 1, 1, 10, 0, 0, '+09:00')]).first
    assert_equal([Time.utc(2024, 1, 1, 2, 0, 0)], f['later'])
    assert_predicate(f.later, :utc?)
  end

  def test_keeps_a_time_in_utc_when_passing_to_the_fact
    fact = Factbase::Fact.new({})
    a = Factbase::Accum.new(fact, {}, true)
    a.t = Time.new(2024, 1, 1, 10, 0, 0, '+09:00')
    assert_predicate(a.t, :utc?)
    assert_equal(Time.utc(2024, 1, 1, 1, 0, 0), fact.t)
  end
end
