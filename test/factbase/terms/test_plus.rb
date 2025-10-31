# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/plus'

# Test for 'plus' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestPlus < Factbase::Test
  def test_plus
    t = Factbase::Plus.new([:foo, 42])
    assert_equal(46, t.evaluate(fact('foo' => 4), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_plus_time
    t = Factbase::Plus.new([:foo, '12 days'])
    assert_equal(Time.parse('2024-01-13'), t.evaluate(fact('foo' => Time.parse('2024-01-01')), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_plus_time_seconds
    time = Time.utc(2000, 1, 1, 0, 0, 21)
    t = Factbase::Plus.new([:foo, '21 seconds'])
    assert_equal(time + 21, t.evaluate(fact('foo' => time), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_plus_time_minutesseconds
    time = Time.utc(2000, 1, 1, 0, 21, 0)
    t = Factbase::Plus.new([:foo, '21 minutes'])
    assert_equal(time + (21 * 60), t.evaluate(fact('foo' => time), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_plus_time_hoursminutes
    time = Time.utc(2000, 1, 1, 21, 0, 0)
    t = Factbase::Plus.new([:foo, '21 hours'])
    assert_equal(time + (21 * 60 * 60), t.evaluate(fact('foo' => time), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_plus_time_weeks
    time = Time.utc(2000, 1, 1, 0, 0, 0)
    t = Factbase::Plus.new([:foo, '3 weeks'])
    assert_equal(time + (3 * 60 * 60 * 24 * 7), t.evaluate(fact('foo' => time), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end
end
