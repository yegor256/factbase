# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_time'

# Test for 'to_time' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToTime < Factbase::Test
  def test_to_time
    t = Factbase::ToTime.new([%w[2023-01-01 hello]])
    assert_equal('Time', t.evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_rejects_unparseable_value
    t = Factbase::ToTime.new(['hello'])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact, [], Factbase.new)
      end
    assert_includes(e.message, "Cannot parse 'hello' as Time in (to_time ...):")
    assert_includes(e.message, 'no time information')
  end

  def test_rejects_out_of_range_value
    t = Factbase::ToTime.new(['2024-13-45'])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact, [], Factbase.new)
      end
    assert_includes(e.message, "Cannot parse '2024-13-45' as Time in (to_time ...):")
    assert_includes(e.message, 'argument out of range')
  end
end
