# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'yaml'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/fact_as_yaml'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestFactAsYaml < Factbase::Test
  def test_prints_exactly
    fb = Factbase.new
    f = fb.insert
    f._id = 1
    f.foo = 42
    f.foo = 33
    f.foo = 42
    f.bar = 'hello, world! how are you?'
    assert_equal(
      "_id: 1\n" \
      "bar: \"hello, world! how are you?\"\n" \
      'foo: [42, 33, 42]',
      Factbase::FactAsYaml.new(f).to_s
    )
  end

  def test_simple_rendering
    fb = Factbase.new
    f = fb.insert
    f._id = 1
    f.foo = 42
    f.bar = 'hello'
    yaml_str = Factbase::FactAsYaml.new(f).to_s
    yaml = YAML.load(yaml_str)
    assert_equal(1, yaml['_id'])
    assert_equal('hello', yaml['bar'])
    assert_equal(42, yaml['foo'])
  end

  def test_multiple_values
    fb = Factbase.new
    f = fb.insert
    f.foo = 42
    f.foo = 256
    f.foo = 512
    yaml_str = Factbase::FactAsYaml.new(f).to_s
    yaml = YAML.load(yaml_str)
    assert_equal([42, 256, 512], yaml['foo'])
  end

  def test_sorted_keys
    fb = Factbase.new
    f = fb.insert
    f.c = 3
    f.a = 1
    f.b = 2
    yaml_str = Factbase::FactAsYaml.new(f).to_s
    assert_operator(yaml_str.index('a:'), :<, yaml_str.index('b:'))
    assert_operator(yaml_str.index('b:'), :<, yaml_str.index('c:'))
  end

  def test_usage_example_from_issue
    fb = Factbase.new
    f = fb.insert
    f._id = 1
    f.name = 'test'
    f = fb.query('(eq _id 1)').each.to_a.first
    yaml_str = Factbase::FactAsYaml.new(f).to_s
    assert(yaml_str)
    assert_includes(yaml_str, '_id')
    assert_includes(yaml_str, 'name')
  end
end
