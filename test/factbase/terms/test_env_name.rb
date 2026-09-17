# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../test__helper'

class TestEnvName < Factbase::Test
  def test_refuses_a_name_that_is_not_a_string
    fb = Factbase.new
    f = fb.insert
    f.n = 'fb_test_var'
    f.i = 5
    assert_includes(
      assert_raises(StandardError, 'a number as the name of an environment variable must be refused') do
        fb.query('(eq n (env i "d"))').each.to_a
      end.message,
      "A string is expected as first argument of 'env'"
    )
  end
end
