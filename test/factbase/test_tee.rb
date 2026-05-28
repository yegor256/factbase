# frozen_string_literal: true

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/accum'
require_relative '../../lib/factbase/fact'
require_relative '../../lib/factbase/tee'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

def global_function_for_test_only(foo)
  raise(foo)
end

# Tee test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
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
    assert_nil(Factbase::Tee.new(prim, Factbase::Fact.new({}))['$foo'])
  end

  def test_fetches_simply
    assert_equal(
      987,
      Factbase::Accum.new(
        Factbase::Tee.new(
          Factbase::Fact.new({ 'foo_bar' => [987] }),
          Factbase::Fact.new({})
        ),
        {}, true
      ).foo_bar
    )
  end

  def test_fetches_without_conflict_with_global_name
    assert_equal(
      2,
      Factbase::Tee.new(Factbase::Fact.new({ 'global_function_for_test_only' => [2] }), Factbase::Fact.new({})).global_function_for_test_only
    )
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
    prim = Factbase::Fact.new({})
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
    assert_equal('[ foo: [42] ]', Factbase::Tee.new(prim, upper).to_s)
  end
end
