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

  def test_anchors_whole_value
    t = Factbase::Matches.new([:foo, '^OK$'])
    assert(t.evaluate(fact('foo' => 'OK'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "FAILED\nOK"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "OK\nFAILED"), [], Factbase.new))
  end

  def test_anchors_dollar_after_closed_character_class
    t = Factbase::Matches.new([:foo, '^[a]$'])
    assert(t.evaluate(fact('foo' => 'a'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "a\nzzz"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "zzz\na"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "x\n[a]\ny"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "x\na\ny"), [], Factbase.new))
  end

  def test_anchors_dollar_at_end_after_character_class
    t = Factbase::Matches.new([:foo, '[a]$'])
    assert(t.evaluate(fact('foo' => 'a'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => "zzz\na"), [], Factbase.new))
    assert(t.evaluate(fact('foo' => "x\ny\na"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "a\nzzz"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "x\n[a]\ny"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "x\na\ny"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "zzz\na\n"), [], Factbase.new))
  end

  def test_anchors_dollar_after_character_class_with_range_or_quantifier
    t = Factbase::Matches.new([:foo, '^[a-z]+$'])
    assert(t.evaluate(fact('foo' => 'hello'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "hello\nworld"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "world\nhello"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "prefix\n[a]\nsuffix"), [], Factbase.new))
  end

  def test_anchors_dollar_after_negated_character_class
    t = Factbase::Matches.new([:foo, '^[^0-9]+$'])
    assert(t.evaluate(fact('foo' => 'abc'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "abc\n123"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "123\nabc"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "first\n[0]\nlast"), [], Factbase.new))
  end

  def test_anchors_dollar_after_multiple_character_classes
    t = Factbase::Matches.new([:foo, '^[a-z][0-9]$'])
    assert(t.evaluate(fact('foo' => 'a1'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "a1\nzzz"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "zzz\na1"), [], Factbase.new))
    refute(t.evaluate(fact('foo' => "x\n[a][0]\ny"), [], Factbase.new))
  end

  def test_keeps_anchor_characters_inside_class_and_escape
    t = Factbase::Matches.new([:foo, '^[^$]\\$$'])
    assert(t.evaluate(fact('foo' => 'a$'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => '$$'), [], Factbase.new))
  end

  def test_matches_negated_unicode_property
    seed = Random.new_seed
    rnd = Random.new(seed)
    text = Array.new(rnd.rand(1..32)) { rnd.rand(0x430..0x44f).chr(Encoding::UTF_8) }.join
    assert(
      Factbase::Matches.new([:foo, '^\\p{^Lu}+$']).evaluate(fact('foo' => text), [], Factbase.new),
      "negated property did not match #{text.inspect}, seed #{seed}"
    )
  end

  def test_dont_match_negated_unicode_property
    seed = Random.new_seed
    rnd = Random.new(seed)
    text = Array.new(rnd.rand(1..32)) { rnd.rand(0x410..0x42f).chr(Encoding::UTF_8) }.join
    refute(
      Factbase::Matches.new([:foo, '\\p{^Lu}']).evaluate(fact('foo' => text), [], Factbase.new),
      "negated property matched #{text.inspect}, seed #{seed}"
    )
  end

  def test_matches_doubly_negated_unicode_property
    seed = Random.new_seed
    rnd = Random.new(seed)
    text = Array.new(rnd.rand(1..32)) { rnd.rand(0x410..0x42f).chr(Encoding::UTF_8) }.join
    assert(
      Factbase::Matches.new([:foo, '^\\P{^Lu}+$']).evaluate(fact('foo' => text), [], Factbase.new),
      "doubly negated property did not match #{text.inspect}, seed #{seed}"
    )
  end

  def test_anchors_whole_value_around_negated_unicode_property
    seed = Random.new_seed
    rnd = Random.new(seed)
    text = "#{rnd.rand(0x410..0x42f).chr(Encoding::UTF_8)}\n#{rnd.rand(0x430..0x44f).chr(Encoding::UTF_8)}"
    refute(
      Factbase::Matches.new([:foo, '^\\p{^Lu}$']).evaluate(fact('foo' => text), [], Factbase.new),
      "anchors around a negated property matched a line of #{text.inspect}, seed #{seed}"
    )
  end

  def test_reuses_compiled_regexp
    t = Factbase::Matches.new([:foo, '[a-z]+'])
    assert(t.evaluate(fact('foo' => 'hello'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 'world'), [], Factbase.new))
    assert_equal(['[a-z]+'], t.instance_variable_get(:@regexps).keys)
  end

  def test_does_not_cache_a_pattern_read_from_a_property
    t = Factbase::Matches.new(%i[foo pattern])
    10.times { |i| t.evaluate(fact('foo' => "v#{i}", 'pattern' => "^v#{i}$"), [], Factbase.new) }
    assert_empty(t.instance_variable_get(:@regexps), 'a pattern read from a property was cached')
  end

  def test_keeps_a_literal_bracket_at_the_start_of_a_class
    [
      ['[]^]', '^', true],
      ['[]^]', 'A', false],
      ['[]$]', '$', true],
      ['[]$]', 'z', false],
      ['[^]^]', 'A', true],
      ['[^]^]', '^', false]
    ].each do |pattern, text, expected|
      assert_equal(
        expected, Factbase::Matches.new([:foo, pattern]).evaluate(fact('foo' => text), [], Factbase.new),
        "#{pattern} on #{text}"
      )
    end
  end

  def test_rejects_invalid_regexp
    t = Factbase::Matches.new([:foo, '[a-'])
    assert_includes(
      assert_raises(RuntimeError) do
        t.evaluate(fact('foo' => 'hello'), [], Factbase.new)
      end.message, "Invalid regexp '[a-'"
    )
  end
end
