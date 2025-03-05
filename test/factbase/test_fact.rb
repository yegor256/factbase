# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/fact'

# Fact test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestFact < Factbase::Test
  def test_injects_data_correctly
    map = {}
    f = Factbase::Fact.new(map)
    f.foo = 1
    f.bar = 2
    f.bar = 3
    assert_equal(2, map.size)
    assert_equal([1], map['foo'])
    assert_equal([2, 3], map['bar'])
  end

  def test_simple_resetting
    map = {}
    f = Factbase::Fact.new(map)
    f.foo = 42
    assert_equal(42, f.foo, f.to_s)
    f.foo = 256
    assert_equal(42, f.foo, f.to_s)
    assert_equal([42, 256], f['foo'], f.to_s)
  end

  def test_keeps_values_unique
    map = {}
    f = Factbase::Fact.new(map)
    f.foo = 42
    f.foo = 'Hello'
    assert_equal(2, map['foo'].size)
    f.foo = 42
    assert_equal(2, map['foo'].size)
  end

  def test_fails_when_empty
    f = Factbase::Fact.new({})
    assert_raises(StandardError) do
      f.something
    end
  end

  def test_fails_when_setting_nil
    f = Factbase::Fact.new({})
    assert_raises(StandardError) do
      f.foo = nil
    end
  end

  def test_fails_when_setting_empty
    f = Factbase::Fact.new({})
    assert_raises(StandardError) do
      f.foo = ''
    end
  end

  def test_fails_when_not_found
    f = Factbase::Fact.new({})
    f.first = 42
    assert_raises(StandardError) do
      f.second
    end
  end

  def test_set_by_name
    f = Factbase::Fact.new({})
    f.send(:_foo_bar=, 42)
    assert_equal(42, f._foo_bar, f.to_s)
  end

  def test_set_twice_same_value
    map = {}
    f = Factbase::Fact.new(map)
    f.foo = 42
    f.foo = 42
    assert_equal([42], map['foo'])
  end

  def test_time_in_utc
    f = Factbase::Fact.new({})
    t = Time.now
    f.foo = t
    assert_equal(t.utc, f.foo)
    assert_equal(t.utc.to_s, f.foo.to_s)
  end

  def test_some_names_are_prohibited
    f = Factbase::Fact.new({})
    assert_raises(StandardError) { f.to_s = 42 }
    assert_raises(StandardError) { f.class = 42 }
  end

  def test_get_all_properties
    f = Factbase::Fact.new({})
    f.foo = 42
    assert_includes(f.all_properties, 'foo')
  end
end
