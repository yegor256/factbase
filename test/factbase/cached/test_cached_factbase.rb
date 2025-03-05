# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'time'
require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/cached/cached_factbase'

# Query test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestCachedQuery < Factbase::Test
  def test_inserts_and_queries
    fb = Factbase::CachedFactbase.new(Factbase.new)
    f = fb.insert
    f.foo = 1
    f.bar = 'test'
    assert_equal(1, fb.query('(and (eq foo 1) (eq bar "test"))').each.to_a.size)
  end
end
