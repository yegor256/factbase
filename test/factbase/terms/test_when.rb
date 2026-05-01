# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/when'

# Test for the 'when' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestWhen < Factbase::Test
  def test_positive
    [
      [Factbase::Always.new, Factbase::Always.new, 'always then always'],
      [Factbase::Never.new, Factbase::Always.new, 'never then always'],
      [Factbase::Never.new, Factbase::Never.new, 'never then never'],
      [Factbase::Unique.new([:foo]), Factbase::Eq.new([:bar, 42]), 'unique foo then eq bar 42'],
      [Factbase::Eq.new([:bar, 52]), Factbase::Eq.new([:bar, 42]), 'eq bar 52 then eq bar 42']
    ].each do |first, second, msg|
      f = fact({ 'foo' => 32, 'bar' => 42 })
      t = Factbase::When.new([first, second])
      assert(t.evaluate(f, [], Factbase.new), msg)
    end
  end

  def test_negative
    [
      [Factbase::Always.new, Factbase::Never.new, 'always then never'],
      [Factbase::Always.new, Factbase::Eq.new([:bar, 52]), 'always then eq bar 52'],
      [Factbase::Unique.new([:foo]), Factbase::Eq.new([:bar, 52]), 'unique foo then eq bar 52']
    ].each do |first, second, msg|
      f = fact({ 'foo' => 22, 'bar' => 42 })
      t = Factbase::When.new([first, second])
      refute(t.evaluate(f, [], Factbase.new), msg)
    end
  end
end
