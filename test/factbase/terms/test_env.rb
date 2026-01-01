# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/env'

# Test for env term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestEnv < Factbase::Test
  def test_env
    ENV.store('FOO', 'bar')
    t = Factbase::Env.new(['FOO', ''])
    assert_equal('bar', t.evaluate(fact, [], Factbase.new))
  end

  def test_default
    ENV.delete('FOO')
    t = Factbase::Env.new(['FOO', 'мой друг'])
    assert_equal('мой друг', t.evaluate(fact, [], Factbase.new))
  end

  def test_when_default_is_absent
    ENV.delete('FOO')
    t = Factbase::Env.new(['FOO'])
    assert_raises(StandardError) { t.evaluate(fact, [], Factbase.new) }
  end
end
