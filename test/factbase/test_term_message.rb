# frozen_string_literal: true

require_relative '../../lib/factbase'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

# Test of the message a failing term produces.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTermMessage < Factbase::Test
  def test_says_the_same_at_every_depth
    assert_equal(failure_of('(plus b 1)'), failure_of('(not (nil (plus b 1)))'))
  end

  def test_does_not_escape_the_quotes_again
    refute_includes(failure_of('(not (nil (plus b 1)))'), '\\"')
  end

  private

  def failure_of(query)
    fb = Factbase.new
    fb.insert.b = 'x'
    fb.query("(as r #{query})").each.to_a
    ''
  rescue StandardError => e
    e.message
  end
end
