# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/sprintf'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

class TestSprintf < Factbase::Test
  def test_sprintf
    assert_equal('hi, Jeff!', Factbase::Sprintf.new(['hi, %s!', 'Jeff']).evaluate(fact, [], Factbase.new))
  end
end
