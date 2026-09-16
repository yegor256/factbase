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
    skip('Windows environment variables are case-insensitive') if Gem.win_platform?
    assert_equal('mine', with('myVar' => 'mine'))
  end

  def test_does_not_read_another_variable
    skip('Windows environment variables are case-insensitive') if Gem.win_platform?
    assert_equal('default', with('MYVAR' => 'other'))
  end

  private

  def with(vars)
    ENV.delete('myVar')
    ENV.delete('MYVAR')
    vars.each { |k, v| ENV.store(k, v) }
    Factbase::Env.new(%w[myVar default]).evaluate(fact, [], Factbase.new)
  ensure
    vars.each_key { |k| ENV.delete(k) }
  end
end
