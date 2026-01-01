# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/as'
require_relative '../../../lib/factbase/syntax'
require_relative '../../../lib/factbase/accum'

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
end
