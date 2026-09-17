# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/logged'
require_relative '../test__helper'

class TestLoggedLength < Factbase::Test
  def test_cuts_a_long_value_down_to_the_limit
    log = Loog::Buffer.new
    Factbase::Logged.new(Factbase.new, log).insert.foo = 'y' * 63
    rendered = log.to_s[/Set 'foo' to (.*) \(String\)/, 1]
    refute_nil(rendered, 'the assignment must be logged')
    assert_operator(
      rendered.length, :<=, Factbase::Logged::Fact::MAX_LENGTH,
      'a shortened value cannot come out longer than the limit it is cut to'
    )
  end
end
