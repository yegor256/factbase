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
  end

  def test_cannot_match_integer
    seed = Random.new_seed
    num = Random.new(seed).rand(1..1_000_000)
    t = Factbase::Matches.new([:foo, num.to_s])
    assert_raises(RuntimeError, "integer #{num} was converted to a string, seed #{seed}") do
      t.evaluate(fact('foo' => num), [], Factbase.new)
    end
  end

  def test_cannot_match_float
    seed = Random.new_seed
    num = Random.new(seed).rand * 1000
    t = Factbase::Matches.new([:foo, num.to_s])
    assert_raises(RuntimeError, "float #{num} was converted to a string, seed #{seed}") do
      t.evaluate(fact('foo' => num), [], Factbase.new)
    end
  end

  def test_cannot_match_time
    seed = Random.new_seed
    time = Time.at(Random.new(seed).rand(0..2_000_000_000)).utc
    t = Factbase::Matches.new([:foo, time.year.to_s])
    assert_raises(RuntimeError, "time #{time} was converted to a string, seed #{seed}") do
      t.evaluate(fact('foo' => time), [], Factbase.new)
    end
  end

  def test_cannot_match_boolean
    seed = Random.new_seed
    flag = Random.new(seed).rand(2).zero?
    t = Factbase::Matches.new([:foo, flag.to_s])
    assert_raises(RuntimeError, "boolean #{flag} was converted to a string, seed #{seed}") do
      t.evaluate(fact('foo' => flag), [], Factbase.new)
    end
  end

  def test_cannot_match_integer_via_query
    seed = Random.new_seed
    fb = Factbase.new
    num = Random.new(seed).rand(1..1_000_000)
    fb.insert.num = num
    assert_raises(RuntimeError, "query matched integer #{num} as a string, seed #{seed}") do
      fb.query("(matches num '#{num}')").each.to_a
    end
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
end
