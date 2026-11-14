# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/env'

require_relative '../../test__helper'

# Test for env term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestEnv < Factbase::Test
  def setup
    super
    @foo = ENV.fetch('FOO', nil)
  end

  def teardown
    if defined?(@foo)
      @foo.nil? ? ENV.delete('FOO') : ENV.store('FOO', @foo)
    end
    super
  end

  def test_env
    ENV.store('FOO', 'bar')
    assert_equal('bar', Factbase::Env.new(['FOO', '']).evaluate(fact, [], Factbase.new))
  end

  def test_default
    ENV.delete('FOO')
    assert_equal('мой друг', Factbase::Env.new(['FOO', 'мой друг']).evaluate(fact, [], Factbase.new))
  end

  def test_default_when_value_is_empty
    ENV.store('FOO', '')
    assert_equal('мой друг', Factbase::Env.new(['FOO', 'мой друг']).evaluate(fact, [], Factbase.new))
  end

  def test_when_default_is_absent
    ENV.delete('FOO')
    t = Factbase::Env.new(['FOO'])
    assert_raises(StandardError) { t.evaluate(fact, [], Factbase.new) }
  end

  def test_missing_attr_returns_nil
    ENV.delete('FOO')
    assert_nil(Factbase::Env.new([:missing_attr, 'fallback']).evaluate(fact, [], Factbase.new))
  end

  def test_missing_default_returns_nil
    ENV.delete('FOO')
    assert_nil(Factbase::Env.new(['FOO', :also_missing]).evaluate(fact, [], Factbase.new))
  end

  def test_keeps_callers_value
    ENV.store('FOO', 'caller')
    TestEnv.new(:test_env).run
    assert_equal('caller', ENV.fetch('FOO', nil))
  end

  def test_restores_after_assertion_raises
    ENV.store('FOO', 'caller')
    raised =
      Class.new(TestEnv) do
        def test_raises
          ENV.store('FOO', 'changed')
          flunk('boom')
        end
      end.new(:test_raises)
    raised.run
    assert_equal(1, raised.failures.size, 'the nested test must actually raise')
    assert_equal('caller', ENV.fetch('FOO', nil))
  end

  def test_keeps_callers_value_when_setup_raises
    ENV.store('FOO', 'caller')
    Class.new(TestEnv) do
      def setup
        raise(RuntimeError, 'setup failed')
      end
    end.new(:test_env).run
    assert_equal('caller', ENV.fetch('FOO', nil))
  end
end
