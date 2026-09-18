# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToIntegerInfinite < Factbase::Test
  def test_names_the_term_when_the_float_is_infinite
    [1.0 / 0, -1.0 / 0, 0.0 / 0].each do |v|
      assert_match(
        /to_integer/,
        assert_raises(RuntimeError, v.to_s) { Factbase::ToInteger.new([v]).evaluate(nil, nil, nil) }.message
      )
    end
  end
end
