# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/minus'

# Test for 'minus' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestMinus < Factbase::Test
  def test_minus
    t = Factbase::Minus.new([:foo, 42])
    assert_equal(58, t.evaluate(fact('foo' => 100), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_minus_time
    t = Factbase::Minus.new([:foo, '4 hours'])
    assert_equal(Time.parse('2024-01-01T06:04'),
                 t.evaluate(fact('foo' => Time.parse('2024-01-01T10:04')), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end

  def test_minus_time_singular
    t = Factbase::Minus.new([:foo, '1 hour'])
    assert_equal(Time.parse('2024-01-01T09:04'),
                 t.evaluate(fact('foo' => Time.parse('2024-01-01T10:04')), [], Factbase.new))
    assert_nil(t.evaluate(fact, [], Factbase.new))
  end
end
