# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/cached/cached_factbase'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestCachedEnv < Factbase::Test
  def test_sees_a_changed_variable
    origin = Factbase.new
    origin.insert.foo = 1
    fb = Factbase::CachedFactbase.new(origin)
    query = '(eq foo (to_integer (env "FACTBASE_TEST_ENV" "1")))'
    ENV['FACTBASE_TEST_ENV'] = '1'
    assert_equal(1, fb.query(query).each.to_a.size)
    ENV['FACTBASE_TEST_ENV'] = '0'
    assert_equal(origin.query(query).each.to_a.size, fb.query(query).each.to_a.size)
  ensure
    ENV.delete('FACTBASE_TEST_ENV')
  end
end
