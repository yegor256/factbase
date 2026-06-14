# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/to_yaml'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToYAML < Factbase::Test
  def test_simple_rendering
    fb = Factbase.new
    f = fb.insert
    f._id = 1
    f.foo = 42
    f.foo = 256
    fb.insert._id = 2
    yaml = YAML.load(Factbase::ToYAML.new(fb).yaml)
    assert_equal(2, yaml.size)
    assert_equal(42, yaml[0]['foo'][0])
    assert_equal(256, yaml[0]['foo'][1])
  end

  def test_sorts_keys
    fb = Factbase.new
    f = fb.insert
    f.b = 42
    f.a = 256
    f.c = 10
    yaml = Factbase::ToYAML.new(fb).yaml
    assert_includes(yaml, "a: 256\n  b: 42\n  c: 10", yaml)
  end

  def test_empty_factbase
    assert_equal("--- []\n", Factbase::ToYAML.new(Factbase.new).yaml)
  end

  def test_time_value
    fb = Factbase.new
    fb.insert.ts = Time.now
    assert_kind_of(Time, YAML.safe_load(Factbase::ToYAML.new(fb).yaml, permitted_classes: [Time, Symbol])[0]['ts'])
  end

  def test_string_value
    fb = Factbase.new
    fb.insert.note = 'hello'
    assert_equal('hello', YAML.load(Factbase::ToYAML.new(fb).yaml)[0]['note'])
  end
end
