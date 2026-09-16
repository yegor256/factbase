# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/env'
require_relative '../../test__helper'

# Test of the name 'env' looks up.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestEnvCase < Factbase::Test
  def test_reads_a_lower_case_variable
    ENV.store('myVar', 'mine')
    ENV.delete('MYVAR')
    assert_equal('mine', Factbase::Env.new(%w[myVar default]).evaluate(fact, [], Factbase.new))
  ensure
    ENV.delete('myVar')
  end

  def test_does_not_read_another_variable
    ENV.delete('myVar')
    ENV.store('MYVAR', 'other')
    assert_equal('default', Factbase::Env.new(%w[myVar default]).evaluate(fact, [], Factbase.new))
  ensure
    ENV.delete('MYVAR')
  end
end
