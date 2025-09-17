# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/accum'
require_relative '../../lib/factbase/fact'

def global_function_for_this_test_only(foo)
  raise foo
end

# Accum test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestAccum < Factbase::Test
  def test_holds_props
    map = {}
    f = Factbase::Fact.new(map)
    props = {}
    a = Factbase::Accum.new(f, props, false)
    a.foo = 42
    assert_raises(StandardError) { f.foo }
    assert_equal(42, a.foo)
    assert_equal([42], props['foo'])
  end

  def test_fetches_without_conflict_with_global_name
    t = Factbase::Accum.new(
      Factbase::Fact.new({ 'global_function_for_this_test_only' => [2] }),
      {}, true
    )
    assert_equal(2, t.global_function_for_this_test_only)
  end

  def test_passes_props
    map = {}
    f = Factbase::Fact.new(map)
    props = {}
    a = Factbase::Accum.new(f, props, true)
    a.foo = 42
    assert_equal(42, f.foo)
    assert_equal(42, a.foo)
    assert_equal([42], props['foo'])
  end

  def test_appends_props
    map = {}
    f = Factbase::Fact.new(map)
    f.foo = 42
    props = {}
    a = Factbase::Accum.new(f, props, false)
    a.foo = 55
    assert_equal(2, a['foo'].size)
  end

  def test_empties
    f = Factbase::Fact.new({})
    a = Factbase::Accum.new(f, {}, false)
    assert_nil(a['foo'])
  end

  def test_prints_to_string
    map = {}
    f = Factbase::Fact.new(map)
    props = {}
    a = Factbase::Accum.new(f, props, true)
    a.foo = 42
    assert_equal('[ foo: [42] ]', f.to_s)
  end

  def test_keep_duplicates
    f = Factbase::Fact.new({})
    a = Factbase::Accum.new(f, {}, true)
    a.foo = 42
    a.foo = 41
    a.foo = 42
    a.foo = 42
    assert_equal([42, 41, 42, 42], f['foo'])
  end
end
