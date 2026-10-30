# frozen_string_literal: true

require_relative '../../../lib/factbase/accum'
require_relative '../../../lib/factbase/syntax'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/as'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'as' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestAs < Factbase::Test
  def test_aliases
    maps = [
      { 'x' => [1], 'y' => [0], 't1' => [Time.now], 't2' => [Time.now] },
      { 'x' => [2], 'y' => [42], 't' => [Time.now] }
    ]
    {
      '(as foo (plus x 1))' => '(exists foo)',
      '(as foo (plus x y))' => '(gt foo 0)',
      '(as foo (plus bar 1))' => '(absent foo)',
      '(as foo (minus t1 t2))' => '(when (exists foo) (eq "Float" (type foo)))'
    }.each do |q, r|
      t = Factbase::Syntax.new(q).to_term
      maps.each do |m|
        f = Factbase::Accum.new(fact(m), {}, false)
        next unless t.evaluate(f, maps, Factbase.new)
        assert(Factbase::Syntax.new(r).to_term.evaluate(f, [], Factbase.new), "#{q} -> #{f}")
      end
    end
  end

  def test_cannot_attach_to_given_parameter
    seed = Random.new_seed
    rnd = Random.new(seed)
    name = "p#{Array.new(rnd.rand(1..16)) { [*'a'..'z'].sample(random: rnd) }.join}"
    fb = Factbase.new
    fb.insert.foo = rnd.rand(1..1000)
    assert_raises(StandardError, "as wrote a property named $#{name}, seed #{seed}") do
      fb.query("(as $#{name} #{rnd.rand(1..1000)})").each(fb, { name => [rnd.rand(1..1000)] }).to_a
    end
  end

  def test_cannot_attach_to_absent_parameter
    seed = Random.new_seed
    rnd = Random.new(seed)
    name = "p#{Array.new(rnd.rand(1..16)) { [*'a'..'z'].sample(random: rnd) }.join}"
    fb = Factbase.new
    fb.insert.foo = rnd.rand(1..1000)
    assert_raises(StandardError, "as wrote a property named $#{name}, seed #{seed}") do
      fb.query("(as $#{name} '#{rnd.rand(0x430..0x44f).chr(Encoding::UTF_8)}')").each(fb, {}).to_a
    end
  end

  def test_cannot_attach_term_value_to_parameter
    seed = Random.new_seed
    rnd = Random.new(seed)
    name = "p#{Array.new(rnd.rand(1..16)) { [*'a'..'z'].sample(random: rnd) }.join}"
    fb = Factbase.new
    fb.insert.foo = rnd.rand(1..1000)
    assert_raises(StandardError, "as wrote a property named $#{name}, seed #{seed}") do
      fb.query("(as $#{name} (plus foo 1))").each(fb, {}).to_a
    end
  end

  def test_attaches_to_name_starting_with_underscore
    seed = Random.new_seed
    rnd = Random.new(seed)
    name = "_#{Array.new(rnd.rand(1..16)) { [*'a'..'z'].sample(random: rnd) }.join}"
    fb = Factbase.new
    fb.insert.foo = rnd.rand(1..1000)
    assert_equal(
      1, fb.query("(and (as #{name} foo) (eq #{name} foo))").each(fb, {}).to_a.size,
      "as refused the property #{name}, seed #{seed}"
    )
  end
end
