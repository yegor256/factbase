# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_string'

# Test for 'to_string' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestToString < Factbase::Test
  def test_to_str
    t = Factbase::ToString.new([Time.now])
    assert_equal('String', t.evaluate(fact, [], Factbase.new).class.to_s)
  end
end
