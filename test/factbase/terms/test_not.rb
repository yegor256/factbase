# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/not'

# Test for the 'not' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestNot < Factbase::Test
  def test_not
    refute(Factbase::Not.new([Factbase::Always.new([])]).evaluate(fact, [], Factbase.new))
  end

  def test_not_reverse
    assert(Factbase::Not.new([Factbase::Never.new([])]).evaluate(fact, [], Factbase.new))
  end

  def test_not_with_arguments
    assert_includes(assert_raises(RuntimeError) do
      Factbase::Term.new(:not, %i[foo bar]).evaluate(fact('foo' => true, 'bar' => false), [], Factbase.new)
    end.message, "Too many (2) operands for 'not' (1 expected)")
  end
end
