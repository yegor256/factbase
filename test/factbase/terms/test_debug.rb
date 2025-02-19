# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative '../../../lib/factbase/term'

# Debug test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestDebug < Minitest::Test
  def test_traced
    t = Factbase::Term.new(Factbase.new, :traced, [Factbase::Term.new(Factbase.new, :defn, [:test_debug, 'self.to_s'])])
    assert_output("(traced (defn test_debug 'self.to_s')) -> true\n") do
      assert(t.evaluate(fact, []))
    end
  end

  def test_traced_raises
    e = assert_raises(StandardError) { Factbase::Term.new(Factbase.new, :traced, ['foo']).evaluate(fact, []) }
    assert_match(/A term expected, but 'foo' provided/, e.message)
  end

  def test_traced_raises_when_too_many_args
    e =
      assert_raises(StandardError) do
        Factbase::Term.new(
          Factbase.new, :traced,
          [Factbase::Term.new(Factbase.new, :defn, [:debug, 'self.to_s']), 'something']
        ).evaluate(fact, [])
      end
    assert_match(/Too many \(\d+\) operands for 'traced' \(\d+ expected\)/, e.message)
  end
end
