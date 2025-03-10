# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'

# Math test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestCasting < Factbase::Test
  def test_to_str
    t = Factbase::Term.new(:to_string, [Time.now])
    assert_equal('String', t.evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_to_integer
    t = Factbase::Term.new(:to_integer, [[42, 'hello']])
    assert_equal('Integer', t.evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_to_float
    t = Factbase::Term.new(:to_float, [[3.14, 'hello']])
    assert_equal('Float', t.evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_to_time
    t = Factbase::Term.new(:to_time, [%w[2023-01-01 hello]])
    assert_equal('Time', t.evaluate(fact, [], Factbase.new).class.to_s)
  end
end
