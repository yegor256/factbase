# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/to_json'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToJSON < Factbase::Test
  def test_simple_rendering
    fb = Factbase.new
    f = fb.insert
    f.foo = 42
    f.foo = 256
    assert_equal(256, JSON.parse(Factbase::ToJSON.new(fb).json)[0]['foo'][1])
  end

  def test_sort_keys
    fb = Factbase.new
    f = fb.insert
    f.c = 42
    f.b = 1
    f.a = 256
    json = Factbase::ToJSON.new(fb).json
    assert_includes(json, '{"a":256,"b":1,"c":42}', json)
  end

  def test_empty_factbase
    assert_equal('[]', Factbase::ToJSON.new(Factbase.new).json)
  end

  def test_time_value
    fb = Factbase.new
    fb.insert.when = Time.now
    json = JSON.parse(Factbase::ToJSON.new(fb).json)
    assert_kind_of(String, json[0]['when'])
    refute_empty(json[0]['when'])
  end

  def test_string_value
    fb = Factbase.new
    fb.insert.text = 'hello'
    assert_equal('hello', JSON.parse(Factbase::ToJSON.new(fb).json)[0]['text'])
  end

  def test_custom_sort_key
    fb = Factbase.new
    fb.insert.prio = 2
    fb.insert.prio = 1
    fb.insert.prio = 3
    json = JSON.parse(Factbase::ToJSON.new(fb, 'prio').json)
    assert_equal(1, json[0]['prio'])
    assert_equal(2, json[1]['prio'])
    assert_equal(3, json[2]['prio'])
  end
end
