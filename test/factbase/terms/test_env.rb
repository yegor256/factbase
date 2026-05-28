# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/env'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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

  def test_when_default_is_absent
    ENV.delete('FOO')
    t = Factbase::Env.new(['FOO'])
    assert_raises(StandardError) { t.evaluate(fact, [], Factbase.new) }
  end
end
