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

  def test_keeps_anchor_characters_inside_class_and_escape
    t = Factbase::Matches.new([:foo, '^[^$]\\$$'])
    assert(t.evaluate(fact('foo' => 'a$'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => '$$'), [], Factbase.new))
  end

  def test_reuses_compiled_regexp
    t = Factbase::Matches.new([:foo, '[a-z]+'])
    assert(t.evaluate(fact('foo' => 'hello'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 'world'), [], Factbase.new))
    assert_equal(['[a-z]+'], t.instance_variable_get(:@regexps).keys)
  end

  def test_rejects_invalid_regexp
    t = Factbase::Matches.new([:foo, '[a-'])
    assert_includes(
      assert_raises(RuntimeError) do
        t.evaluate(fact('foo' => 'hello'), [], Factbase.new)
      end.message, "Invalid regexp '[a-'"
    )
  end

  def test_dont_match_when_pattern_property_is_absent
    seed = Random.new_seed
    rnd = Random.new(seed)
    text = Array.new(rnd.rand(1..32)) { rnd.rand(0x430..0x44f).chr(Encoding::UTF_8) }.join
    refute(
      Factbase::Matches.new(%i[foo pattern]).evaluate(fact('foo' => text), [], Factbase.new),
      "matches found a pattern in an absent property for #{text.inspect}, seed #{seed}"
    )
  end

  def test_dont_match_when_both_operands_are_absent
    seed = Random.new_seed
    refute(
      Factbase::Matches.new(%i[foo pattern]).evaluate(fact('bar' => Random.new(seed).rand(1..1000)), [], Factbase.new),
      "matches found something in absent operands, seed #{seed}"
    )
  end

  def test_skips_facts_without_pattern_property
    seed = Random.new_seed
    rnd = Random.new(seed)
    fb = Factbase.new
    text = Array.new(rnd.rand(1..32)) { rnd.rand(0x430..0x44f).chr(Encoding::UTF_8) }.join
    f = fb.insert
    f.name = text
    f.pat = "^#{text[0]}"
    fb.insert.name = text
    assert_equal(
      1, fb.query('(matches name pat)').each.to_a.size,
      "facts for #{text.inspect} were not skipped, seed #{seed}"
    )
  end

  def test_dont_match_when_pattern_parameter_is_absent
    seed = Random.new_seed
    rnd = Random.new(seed)
    fb = Factbase.new
    fb.insert.name = Array.new(rnd.rand(1..32)) { rnd.rand(0x430..0x44f).chr(Encoding::UTF_8) }.join
    assert_empty(fb.query('(matches name $p)').each(fb, {}).to_a, "an absent parameter matched, seed #{seed}")
  end
end
