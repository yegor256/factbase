# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/head'
require_relative '../../test__helper'

# Test for head term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestHead < Factbase::Test
  def test_takes_the_first_ones
    maps = [{ 'foo' => [1] }, { 'foo' => [2] }, { 'foo' => [3] }]
    assert_equal(
      2,
      Factbase::Term.new(:head, [2, Factbase::Term.new(:always, [])]).predict(maps, Factbase.new(maps), {}).size
    )
  end

  def test_refuses_a_negative_count
    maps = [{ 'foo' => [1] }]
    t = Factbase::Term.new(:head, [-1, Factbase::Term.new(:always, [])])
    e = assert_raises(ArgumentError) { t.predict(maps, Factbase.new(maps), {}) }
    assert_includes(e.message, "A non-negative count is expected by 'head', but -1 provided", e.message)
  end
end
