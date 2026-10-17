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

  def test_rejects_substring_in_middle_or_at_end
    refute(Factbase::StartsWith.new([:foo, 'Objects']).evaluate(fact('foo' => 'Elegant Objects'), [], Factbase.new))
    refute(Factbase::StartsWith.new([:foo, 'gant']).evaluate(fact('foo' => 'Elegant Objects'), [], Factbase.new))
    refute(Factbase::StartsWith.new([:bar, 'World']).evaluate(fact('bar' => 'HelloWorld'), [], Factbase.new))
    refute(Factbase::StartsWith.new([:bar, 'loWo']).evaluate(fact('bar' => 'HelloWorld'), [], Factbase.new))
  end

  def test_single_character_prefix
    t = Factbase::StartsWith.new([:foo, 'H'])
    assert(t.evaluate(fact('foo' => 'HelloWorld'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 'eHelloWorld'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 'WorldH'), [], Factbase.new))
  end

  def test_empty_prefix
    t = Factbase::StartsWith.new([:foo, ''])
    assert(t.evaluate(fact('foo' => 'hello'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 'Elegant Objects'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => ''), [], Factbase.new))
  end

  def test_empty_string_does_not_start_with_non_empty_prefix
    t = Factbase::StartsWith.new([:foo, 'a'])
    refute(t.evaluate(fact('foo' => ''), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 'ba'), [], Factbase.new))
  end

  def test_shorter_string_does_not_start_with_longer_prefix
    t = Factbase::StartsWith.new([:foo, 'HelloWorld'])
    refute(t.evaluate(fact('foo' => 'Hello'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 'World'), [], Factbase.new))
  end

  def test_multi_valued_property_rejects_substring_later_in_values
    t = Factbase::StartsWith.new([:tags, 'rails'])
    refute(t.evaluate(fact('tags' => %w[grails derails]), [], Factbase.new))
    assert(t.evaluate(fact('tags' => ['grails', 'rails on fire']), [], Factbase.new))
  end

  def test_multiple_prefixes_from_property
    t = Factbase::StartsWith.new(%i[text prefixes])
    refute(t.evaluate(fact('text' => 'HelloWorld', 'prefixes' => %w[World loWo]), [], Factbase.new))
    assert(t.evaluate(fact('text' => 'HelloWorld', 'prefixes' => %w[World Hello]), [], Factbase.new))
  end

  def test_query_rejects_substring_later_in_value
    fb = Factbase.new
    f = fb.insert
    f.title = 'Elegant Objects'
    f.word = 'HelloWorld'
    assert_empty(fb.query("(starts_with title 'Objects')").each.to_a)
    assert_empty(fb.query("(starts_with title 'gant')").each.to_a)
    assert_empty(fb.query("(starts_with word 'World')").each.to_a)
    assert_empty(fb.query("(starts_with word 'loWo')").each.to_a)
  end

  def test_query_with_multi_valued_property
    fb = Factbase.new
    f1 = fb.insert
    f1.title = 'Object Thinking'
    f1.title = 'Elegant Objects'
    f2 = fb.insert
    f2.title = 'Thinking in Java'
    f2.title = 'Learning Java'
    assert_equal(1, fb.query("(starts_with title 'Elegant')").each.to_a.size)
    assert_equal(1, fb.query("(starts_with title 'Object')").each.to_a.size)
    assert_equal(1, fb.query("(starts_with title 'Thinking')").each.to_a.size)
    assert_empty(fb.query("(starts_with title 'Objects')").each.to_a)
    assert_empty(fb.query("(starts_with title 'Java')").each.to_a)
  end
end
