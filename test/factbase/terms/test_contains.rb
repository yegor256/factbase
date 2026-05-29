# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Test for contains term.
# License:: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/contains'

class TestContains < Factbase::Test
  def test_string_substring
    t = Factbase::Contains.new([:foo, 'ell'])
    assert(t.evaluate(fact('foo' => 'hello'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 'world'), [], Factbase.new))
  end

  def test_multi_value_property
    t = Factbase::Contains.new([:tags, 'ruby'])
    assert(t.evaluate(fact('tags' => %w[ruby rails]), [], Factbase.new))
    refute(t.evaluate(fact('tags' => %w[python go]), [], Factbase.new))
  end

  def test_via_query_dispatch
    fb = Factbase.new
    f = fb.insert
    f.title = 'Object Thinking'
    f.title = 'Elegant Objects'
    found = fb.query("(contains title 'Elegant')").each.to_a
    assert_equal(1, found.size)
  end
end
