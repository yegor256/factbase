# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase/fact'
require_relative '../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestFactPropName < Factbase::Test
  def test_refuses_a_name_with_a_newline
    f = Factbase::Fact.new({})
    assert_raises(ArgumentError) { f.public_send(:"weird\nProp!!!=", 42) }
    assert_empty(f.all_properties)
  end
end
