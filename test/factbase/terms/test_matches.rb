# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/matches'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

class TestMatches < Factbase::Test
  def test_regexp_matching
    t = Factbase::Matches.new([:foo, '[a-z]+'])
    assert(t.evaluate(fact('foo' => 'hello'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 'hello 42'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 42), [], Factbase.new))
  end

  def test_regexp_from_property
    t = Factbase::Matches.new(%i[foo pattern])
    assert(t.evaluate(fact('foo' => 'hello', 'pattern' => '^he'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 'hello', 'pattern' => '42$'), [], Factbase.new))
  end

  def test_reuses_compiled_regexp
    t = Factbase::Matches.new([:foo, '[a-z]+'])
    assert(t.evaluate(fact('foo' => 'hello'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 'world'), [], Factbase.new))
    assert_equal(['[a-z]+'], t.instance_variable_get(:@regexps).keys)
  end

  def test_rejects_invalid_regexp
    t = Factbase::Matches.new([:foo, '[a-'])
    e =
      assert_raises(RuntimeError) do
        t.evaluate(fact('foo' => 'hello'), [], Factbase.new)
      end
    assert_includes(e.message, "Invalid regexp '[a-'")
  end
end
