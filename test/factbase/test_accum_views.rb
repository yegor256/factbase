# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestAccumViews < Factbase::Test
  def test_reads_accumulated_prop_through_brackets
    fb = Factbase.new
    fb.insert.foo = 1
    fb.query('(as foo 7)').each do |f|
      assert_equal(7, f.foo)
      assert_includes(f['foo'], 7)
      assert_equal(f.foo, f['foo'][0])
    end
  end
end
