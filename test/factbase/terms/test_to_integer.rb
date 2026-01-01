# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_integer'

# Test for 'to_integer' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToInteger < Factbase::Test
  def test_to_integer
    t = Factbase::ToInteger.new([[42, 'hello']])
    assert_equal('Integer', t.evaluate(fact, [], Factbase.new).class.to_s)
  end
end
