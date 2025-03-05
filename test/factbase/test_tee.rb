# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/tee'
require_relative '../../lib/factbase/fact'

# Tee test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestTee < Factbase::Test
  def test_two_facts
    prim = Factbase::Fact.new({})
    prim.foo = 42
    upper = Factbase::Fact.new({})
    upper.bar = 13
    t = Factbase::Tee.new(prim, upper)
    assert_equal(42, t.foo)
    assert_equal([13], t['$bar'])
  end

  def test_all_properties
    prim = Factbase::Fact.new({})
    prim.foo = 42
    upper = Factbase::Fact.new({})
    upper.bar = 13
    t = Factbase::Tee.new(prim, upper)
    assert_includes(t.all_properties, 'foo')
    assert_includes(t.all_properties, 'bar')
  end

  def test_recursively
    map = {}
    prim = Factbase::Fact.new(map)
    prim.foo = 42
    t = Factbase::Tee.new(nil, { 'bar' => 7 })
    assert_equal(7, t['$bar'])
    t = Factbase::Tee.new(prim, t)
    assert_equal(7, t['$bar'])
  end

  def test_prints_to_string
    prim = Factbase::Fact.new({})
    prim.foo = 42
    upper = Factbase::Fact.new({})
    upper.bar = 13
    t = Factbase::Tee.new(prim, upper)
    assert_equal('[ foo: [42] ]', t.to_s)
  end
end
