# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'

# Ordering test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestOrdering < Factbase::Test
  def test_prev
    t = Factbase::Term.new(:prev, [:foo])
    assert_nil(t.evaluate(fact('foo' => 41), []))
    assert_equal([41], t.evaluate(fact('foo' => 5), []))
    assert_equal([5], t.evaluate(fact('foo' => 6), []))
  end

  def test_unique
    t = Factbase::Term.new(:unique, [:foo])
    refute(t.evaluate(fact, []))
    assert(t.evaluate(fact('foo' => 41), []))
    refute(t.evaluate(fact('foo' => 41), []))
    assert(t.evaluate(fact('foo' => 1), []))
  end
end
