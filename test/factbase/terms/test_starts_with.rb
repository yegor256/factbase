# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/starts_with'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

class TestStartsWith < Factbase::Test
  def test_string_prefix_matches
    t = Factbase::StartsWith.new([:foo, 'hell'])
    assert(t.evaluate(fact('foo' => 'hello'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 'world'), [], Factbase.new))
  end

  def test_any_value_in_array_matches
    t = Factbase::StartsWith.new([:tags, 'ru'])
    assert(t.evaluate(fact('tags' => %w[ruby rails]), [], Factbase.new))
    refute(t.evaluate(fact('tags' => %w[python go]), [], Factbase.new))
  end

  def test_via_query_dispatch
    fb = Factbase.new
    f = fb.insert
    f.title = 'Object Thinking'
    f.title = 'Elegant Objects'
    assert_equal(1, fb.query("(starts_with title 'Elegant')").each.to_a.size)
  end
end
