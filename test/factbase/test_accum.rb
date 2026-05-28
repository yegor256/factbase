# frozen_string_literal: true

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/accum'
require_relative '../../lib/factbase/fact'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

def global_function_for_this_test_only(foo)
  raise(foo)
end

# Accum test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestAccum < Factbase::Test
  def test_holds_props
    f = Factbase::Fact.new({})
    props = {}
    a = Factbase::Accum.new(f, props, false)
    a.foo = 42
    assert_raises(StandardError) { f.foo }
    assert_equal(42, a.foo)
    assert_equal([42], props['foo'])
  end

  def test_fetches_without_conflict_with_global_name
    assert_equal(
      2,
      Factbase::Accum.new(
        Factbase::Fact.new({ 'global_function_for_this_test_only' => [2] }), {},
        true
      ).global_function_for_this_test_only
    )
  end

  def test_passes_props
    f = Factbase::Fact.new({})
    props = {}
    a = Factbase::Accum.new(f, props, true)
    a.foo = 42
    assert_equal(42, f.foo)
    assert_equal(42, a.foo)
    assert_equal([42], props['foo'])
  end

  def test_appends_props
    f = Factbase::Fact.new({})
    f.foo = 42
    a = Factbase::Accum.new(f, {}, false)
    a.foo = 55
    assert_equal(2, a['foo'].size)
  end

  def test_empties
    assert_nil(Factbase::Accum.new(Factbase::Fact.new({}), {}, false)['foo'])
  end

  def test_prints_to_string
    f = Factbase::Fact.new({})
    Factbase::Accum.new(f, {}, true).foo = 42
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
