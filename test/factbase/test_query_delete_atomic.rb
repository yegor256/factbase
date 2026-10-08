# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/impatient'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestQueryDeleteAtomic < Factbase::Test
  def test_deletes_nothing_when_it_times_out
    fb = Factbase.new
    20_000.times do |i|
      f = fb.insert
      f.foo = i
      f.bar = "x#{i}"
    end
    imp = Factbase::Impatient.new(fb, timeout: 0.05)
    assert_raises(StandardError) do
      imp.query('(and (exists foo) (matches bar "^x[0-9]*$"))').delete!
    end
    assert_equal(20_000, fb.size)
  end
end
