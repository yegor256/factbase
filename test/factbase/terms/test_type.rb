# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/type'

# Test for 'type' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestType < Factbase::Test
  def test_type
    t = Factbase::Type.new([:foo])
    assert_equal('nil', t.evaluate(fact('foo' => nil), [], Factbase.new))
    assert_equal('Integer', t.evaluate(fact('foo' => [1]), [], Factbase.new))
    assert_equal('Array', t.evaluate(fact('foo' => [1, 2]), [], Factbase.new))
    assert_equal('String', t.evaluate(fact('foo' => 'bar'), [], Factbase.new))
    assert_equal('Float', t.evaluate(fact('foo' => 2.1), [], Factbase.new))
    assert_equal('Time', t.evaluate(fact('foo' => Time.now), [], Factbase.new))
  end
end
