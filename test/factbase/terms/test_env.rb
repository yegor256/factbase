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

  def test_default_as_integer
    ENV.delete('FOO')
    res = Factbase::Env.new(['FOO', 80]).evaluate(fact, [], Factbase.new)
    assert_equal('80', res)
    assert_instance_of(String, res)
  end

  def test_default_as_float
    ENV.delete('FOO')
    res = Factbase::Env.new(['FOO', 80.5]).evaluate(fact, [], Factbase.new)
    assert_equal('80.5', res)
    assert_instance_of(String, res)
  end

  def test_default_as_symbol
    ENV.delete('FOO')
    res = Factbase::Env.new(['FOO', :bar]).evaluate(fact('bar' => 80), [], Factbase.new)
    assert_equal('80', res)
    assert_instance_of(String, res)
  end

  def test_default_as_symbol_float
    ENV.delete('FOO')
    res = Factbase::Env.new(['FOO', :rate]).evaluate(fact('rate' => 3.14), [], Factbase.new)
    assert_equal('3.14', res)
    assert_instance_of(String, res)
  end

  def test_query_eq_env_with_default_when_unset
    ENV.delete('FOO')
    fb = Factbase.new
    fb.insert
    assert_equal(1, fb.query('(eq (env \'FOO\' 80) "80")').each.to_a.size)
  end

  def test_query_eq_env_with_default_when_set
    ENV.store('FOO', '80')
    fb = Factbase.new
    fb.insert
    assert_equal(1, fb.query('(eq (env \'FOO\' 80) "80")').each.to_a.size)
  ensure
    ENV.delete('FOO')
  end

  def test_query_eq_env_int_comparison_behaves_identically
    ENV.delete('FOO')
    fb = Factbase.new
    fb.insert
    assert_equal(0, fb.query('(eq (env \'FOO\' 80) 80)').each.to_a.size)
    ENV.store('FOO', '80')
    assert_equal(0, fb.query('(eq (env \'FOO\' 80) 80)').each.to_a.size)
  ensure
    ENV.delete('FOO')
  end

  def test_query_eq_env_with_symbol_default
    ENV.delete('FOO')
    fb = Factbase.new
    fb.insert.port = 80
    assert_equal(1, fb.query('(eq (env \'FOO\' port) "80")').each.to_a.size)
    ENV.store('FOO', '80')
    assert_equal(1, fb.query('(eq (env \'FOO\' port) "80")').each.to_a.size)
  ensure
    ENV.delete('FOO')
  end
end
