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
  KEYS = %w[myVar MYVAR].freeze

  def setup
    super
    @saved = KEYS.to_h { |k| [k, ENV.fetch(k, nil)] }
  end

  def teardown
    @saved&.each { |k, v| v.nil? ? ENV.delete(k) : ENV.store(k, v) }
    super
  end

  def test_reads_a_lower_case_variable
    skip('Windows environment variables are case-insensitive') if Gem.win_platform?
    assert_equal('mine', with('myVar' => 'mine'))
  end

  def test_does_not_read_another_variable
    skip('Windows environment variables are case-insensitive') if Gem.win_platform?
    assert_equal('default', with('MYVAR' => 'other'))
  end

  def test_restores_callers_values
    skip('Windows environment variables are case-insensitive') if Gem.win_platform?
    ENV.store('myVar', 'caller')
    ENV.store('MYVAR', 'other-caller')
    TestEnvCase.new(:test_reads_a_lower_case_variable).run
    assert_equal('caller', ENV.fetch('myVar', nil))
    assert_equal('other-caller', ENV.fetch('MYVAR', nil))
  end

  def test_restores_callers_values_on_raise
    skip('Windows environment variables are case-insensitive') if Gem.win_platform?
    ENV.store('myVar', 'caller')
    ENV.store('MYVAR', 'other-caller')
    raised =
      Class.new(TestEnvCase) do
        def test_raises
          ENV.store('myVar', 'changed')
          ENV.delete('MYVAR')
          flunk('boom')
        end
      end.new(:test_raises)
    raised.run
    assert_equal(1, raised.failures.size, 'the nested test must actually raise')
    assert_equal('caller', ENV.fetch('myVar', nil))
    assert_equal('other-caller', ENV.fetch('MYVAR', nil))
  end

  def test_does_not_mask_setup_error
    skip('Windows environment variables are case-insensitive') if Gem.win_platform?
    ENV.store('myVar', 'caller')
    raised =
      Class.new(TestEnvCase) do
        def setup
          raise(RuntimeError, 'setup failed')
        end
      end.new(:test_reads_a_lower_case_variable)
    raised.run
    assert_equal(1, raised.failures.size, 'teardown must not add its own failure')
    assert_equal('caller', ENV.fetch('myVar', nil))
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
