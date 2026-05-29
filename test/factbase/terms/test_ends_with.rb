# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Test for ends_with term.
# License:: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/ends_with'

class TestEndsWith < Factbase::Test
  def test_string_suffix_matches
    t = Factbase::EndsWith.new([:foo, 'llo'])
    assert(t.evaluate(fact('foo' => 'hello'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 'world'), [], Factbase.new))
  end

  def test_any_value_in_array_matches
    t = Factbase::EndsWith.new([:tags, 'by'])
    assert(t.evaluate(fact('tags' => %w[ruby rails]), [], Factbase.new))
    refute(t.evaluate(fact('tags' => %w[python go]), [], Factbase.new))
  end

  def test_via_query_dispatch
    fb = Factbase.new
    f = fb.insert
    f.title = 'Object Thinking'
    f.title = 'Elegant Objects'
    found = fb.query("(ends_with title 'Objects')").each.to_a
    assert_equal(1, found.size)
  end
end
