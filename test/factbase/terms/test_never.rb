# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/never'

# Test for the 'never' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestNever < Factbase::Test
  def test_never
    t = Factbase::Never.new([])
    refute(t.evaluate(fact, [], Factbase.new))
    refute(t.evaluate(fact('foo' => 41), [], Factbase.new))
  end

  def test_never_with_arguments
    assert_includes(assert_raises(RuntimeError) do
      Factbase::Term.new(:never, %i[foo bar]).evaluate(fact('foo' => 1, 'bar' => 'a'), [], Factbase.new)
    end.message, "Too many (2) operands for 'never' (0 expected)")
  end
end
