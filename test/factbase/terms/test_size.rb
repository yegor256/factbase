# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/size'

# Test for 'size' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestSize < Factbase::Test
  def test_size
    t = Factbase::Size.new([:foo])
    assert_equal(1, t.evaluate(fact('foo' => 41), [], Factbase.new))
    assert_equal(0, t.evaluate(fact('foo' => nil), [], Factbase.new))
    assert_equal(4, t.evaluate(fact('foo' => [1, 2, 3, 4]), [], Factbase.new))
    assert_equal(0, t.evaluate(fact('foo' => []), [], Factbase.new))
    assert_equal(1, t.evaluate(fact('foo' => ''), [], Factbase.new))
  end
end
