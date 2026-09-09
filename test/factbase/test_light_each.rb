# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/to_json'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestLightEach < Factbase::Test
  def test_prints_inside_a_transaction
    fb = Factbase.new
    fb.insert.foo = 1
    json = nil
    fb.txn { |t| json = Factbase::ToJSON.new(t).json }
    assert_includes(json, 'foo')
  end
end
