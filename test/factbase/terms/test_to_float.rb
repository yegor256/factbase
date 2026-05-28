# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_float'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'to_float' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToFloat < Factbase::Test
  def test_to_float
    assert_equal('Float', Factbase::ToFloat.new([[3.14, 'hello']]).evaluate(fact, [], Factbase.new).class.to_s)
  end
end
