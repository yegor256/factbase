# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/always'

# Test for the 'always' term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestAlways < Factbase::Test
  def test_always
    t = Factbase::Always.new([])
    assert(t.evaluate(fact, [], Factbase.new))
    assert(t.evaluate(fact('foo' => 41), [], Factbase.new))
  end

  def test_always_with_arguments
    assert_includes(assert_raises(RuntimeError) do
      Factbase::Term.new(:always, %i[foo bar]).evaluate(fact('foo' => 1, 'bar' => 'a'), [], Factbase.new)
    end.message, "Too many (2) operands for 'always' (0 expected)")
  end
end
