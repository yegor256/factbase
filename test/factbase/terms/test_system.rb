# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'

# System test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestSystem < Minitest::Test
  def test_env
    ENV.store('FOO', 'bar')
    t = Factbase::Term.new(Factbase.new, :env, ['FOO', ''])
    assert_equal('bar', t.evaluate(fact, []))
  end

  def test_default
    ENV.delete('FOO')
    t = Factbase::Term.new(Factbase.new, :env, ['FOO', 'мой друг'])
    assert_equal('мой друг', t.evaluate(fact, []))
  end

  def test_when_default_is_absent
    ENV.delete('FOO')
    t = Factbase::Term.new(Factbase.new, :env, ['FOO'])
    assert_raises(StandardError) { t.evaluate(fact, []) }
  end
end
