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
class TestToTimeDateless < Factbase::Test
  def test_refuses_a_time_of_day_with_no_date
    fb = Factbase.new
    f = fb.insert
    f.label = '10:30:00'
    assert_match(
      /carries no date/, assert_raises(RuntimeError) do
                           Factbase::Term.new(:to_time, [:label]).evaluate(f, [f], fb)
                         end.message
    )
  end

  def test_takes_a_date_with_no_time
    fb = Factbase.new
    f = fb.insert
    f.label = '2023-01-01'
    assert_equal(Time.parse('2023-01-01'), Factbase::Term.new(:to_time, [:label]).evaluate(f, [f], fb))
  end
end
