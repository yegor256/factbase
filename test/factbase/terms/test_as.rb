# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/accum'
require_relative '../../../lib/factbase/syntax'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/as'

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

  def test_rejects_a_name_that_is_not_a_symbol
    fb = Factbase.new
    fb.insert.a = 1
    {
      "(as 'x' 1)" => /A symbol is expected as first argument of 'as'/,
      '(as 42 1)' => /A symbol is expected as first argument of 'as'/,
      '(and (always) (as 42 1))' => /A symbol is expected as first argument of 'as'/
    }.each do |q, msg|
      assert_match(msg, assert_raises(StandardError, q) { fb.query(q).each.to_a }.message, q)
      assert_equal(0, fb.query('(not (always))').each.to_a.size, "#{q} left a fact behind")
    end
  end
end
