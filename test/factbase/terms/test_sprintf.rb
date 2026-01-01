# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Test for unique term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/sprintf'

class TestSprintf < Factbase::Test
  def test_sprintf
    t = Factbase::Sprintf.new(['hi, %s!', 'Jeff'])
    assert_equal('hi, Jeff!', t.evaluate(fact, [], Factbase.new))
  end
end
