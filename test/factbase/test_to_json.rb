# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/to_json'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestToJSON < Minitest::Test
  def test_simple_rendering
    fb = Factbase.new
    f = fb.insert
    f.foo = 42
    f.foo = 256
    to = Factbase::ToJSON.new(fb)
    json = JSON.parse(to.json)
    assert_equal(256, json[0]['foo'][1])
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
end
