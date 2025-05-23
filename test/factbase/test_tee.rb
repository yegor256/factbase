# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/accum'
require_relative '../../lib/factbase/tee'
require_relative '../../lib/factbase/fact'

def global_function_for_test_only(foo)
  raise foo
end

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

  def test_no_trip_to_prim_if_not_found
    prim = Factbase::Fact.new({})
    prim.foo = 777
    t = Factbase::Tee.new(prim, Factbase::Fact.new({}))
    assert_nil(t['$foo'])
  end

  def test_fetches_simply
    t = Factbase::Accum.new(
      Factbase::Tee.new(
        Factbase::Fact.new({ 'foo_bar' => [987] }),
        Factbase::Fact.new({})
      ),
      {}, true
    )
    assert_equal(987, t.foo_bar)
  end

  def test_fetches_without_conflict_with_global_name
    t = Factbase::Tee.new(
      Factbase::Fact.new({ 'global_function_for_test_only' => [2] }),
      Factbase::Fact.new({})
    )
    assert_equal(2, t.global_function_for_test_only)
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
    t = Factbase::Tee.new(Factbase::Fact.new({}), { 'bar' => [7] })
    assert_equal([7], t['$bar'])
    t = Factbase::Tee.new(prim, t)
    assert_equal([7], t['$bar'])
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
