# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/traced'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for traced term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTraced < Factbase::Test
  def test_traced
    t = Factbase::Traced.new([Factbase::Term.new(:defn, [:test_debug, 'self.to_s'])])
    assert_output("(traced (defn test_debug 'self.to_s')) -> true\n") do
      assert(t.evaluate(fact, [], Factbase.new))
    end
  end

  def test_traced_raises
    assert_match(
      /A term is expected, but 'foo' provided/,
      assert_raises(StandardError) do
        Factbase::Traced.new(['foo']).evaluate(fact, [], Factbase.new)
      end.message
    )
  end

  def test_traced_raises_when_too_many_args
    assert_match(
      /Too many \(\d+\) operands for 'traced' \(\d+ expected\)/,
      assert_raises(StandardError) do
        Factbase::Traced.new(
          [Factbase::Term.new(:defn, [:debug, 'self.to_s']), 'something']
        ).evaluate(fact, [], Factbase.new)
      end.message
    )
  end
end
