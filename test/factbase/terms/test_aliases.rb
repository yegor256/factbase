# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/syntax'
require_relative '../../../lib/factbase/accum'

# Aliases test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestAliases < Factbase::Test
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
      t = Factbase::Syntax.new(Factbase.new, q).to_term
      maps.each do |m|
        f = Factbase::Accum.new(fact(m), {}, false)
        next unless t.evaluate(f, maps)
        assert(Factbase::Syntax.new(Factbase.new, r).to_term.evaluate(f, []), "#{q} -> #{f}")
      end
    end
  end

  def test_join
    maps = [
      { 'x' => 1, 'y' => 0, 'z' => 4 },
      { 'x' => [2], 'bar' => [44, 55, 66] }
    ]
    {
      '(join "foo_x<=x" (gt x 1))' => '(exists foo_x)',
      '(join "foo <=bar  " (exists bar))' => '(and (eq foo 44) (eq foo 55))',
      '(join "uuu" (eq x 1))' => '(absent uuu)',
      '(join "uuu <= fff" (eq fff 1))' => '(absent uuu)'
    }.each do |q, r|
      t = Factbase::Syntax.new(Factbase.new, q).to_term
      maps.each do |m|
        f = Factbase::Accum.new(fact(m), {}, false)
        require_relative '../../../lib/factbase/logged'
        f = Factbase::Logged::Fact.new(f, Loog::NULL)
        next unless t.evaluate(f, maps)
        assert(Factbase::Syntax.new(Factbase.new, r).to_term.evaluate(f, []), "#{q} -> #{f} doesn't match #{r}")
      end
    end
  end
end
